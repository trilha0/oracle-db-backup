#!/bin/bash
# Versao..: 202008171420
# Autor...: Marcos Braga | braga.marcos at gmail.com
# Data....: 19/10/2019
# Script..: backup-db.sh
#
# Script para backup fisico e gerencia dos archives
#
# entrada em /etc/crontab
# 0 23 * * * oracle /home/oracle/bin/backup-db.sh
#
##########
# Adicionar o caminho de destino dos arquivos de backup
#
export _ORADES=
#
# Quantos dias manter archives no disco
#
export _ARCDIAS=7
#
# Diretorio onde sao gravados os archives
#
export _ORAARC=
#
# Nome do banco de dados, ORACLE_SID
#
export ORACLE_SID=
#
# Diretorio do ORACLE_BASE
#
export ORACLE_BASE=
#
# Diretorio do ORACLE_HOME
#
export ORACLE_HOME=
#
# Localizacao do arquivo de funcoes
#
export _FX="/home/oracle/bin/funcoes.mab"
#
##########
# If you have not sure about what you're doing, please don't
# change the script from this point
##########
#
# Validating the variables
[ -z $_ORADES ]     && echo -e "\nFalta Editar o Script, ver linha 15\n" && exit 1
[ -z $_ARCDIAS ]    && echo -e "\nFalta Editar o Script, ver linha 19\n" && exit 1
[ -z $_ORAARC ]     && echo -e "\nFalta Editar o Script, ver linha 23\n" && exit 1
[ -z $ORACLE_SID ]  && echo -e "\nFalta Editar o Script, ver linha 27\n" && exit 1
[ -z $ORACLE_BASE ] && echo -e "\nFalta Editar o Script, ver linha 31\n" && exit 1
[ -z $ORACLE_HOME ] && echo -e "\nFalta Editar o Script, ver linha 35\n" && exit 1
[ -f $_FX ] && echo -e "\nArquivo de Funcoes nao encontrado\nVer linha 39\n" && exit 1
# path
export PATH=$ORACLE_HOME/bin:$PATH
#
# Script Start...
_F0=${0%'.'*}
_F1=$_F0.rman
_F2=$_F0.log
_F3=restaura-db.leiame
_F4=orapw${ORACLE_SID}
#
# data e hora
An=$(date +%Y)  # ano
Me=$(date +%m)  # mes
Di=$(date +%d)  # dia
Hr=$(date +%H)  # hora
Mi=$(date +%M)  # minutos
Se=$(date +%S)  # segundos
#
# load functions
. $_FX
#
# executing logfile rotate
[ -f "$_F2" ] && rotateLog $_F2
#
# registrando tudo...
fLog $_F2 "Script Inicio..."
#
fLog $_F2 "Criando arquivo com os comandos rman"
#
>$_F1 cat <<EOF
connect target /
run {
configure controlfile autobackup off;
crosscheck backup;
crosscheck archivelog all;
allocate channel d1 type disk format '${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-database-full-backup-%U';
backup tag bkp_database as compressed backupset not backed up 1 times database;
release channel d1;
allocate channel d2 type disk format '${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-archives-backup-%U';
backup tag bkp_archives as compressed backupset not backed up 1 times archivelog all;
release channel d2;
allocate channel d3 type disk format '${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-spfilefile-backup-%U';
backup tag bkp_spfile (spfile);
release channel d3;
allocate channel d4 type disk format '${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-controlfile-backup-%U';
backup tag bkp_controlfile (current controlfile);
release channel d4;
delete noprompt expired backup;
change archivelog from time 'sysdate-${_ARCDIAS}' uncatalog;
delete noprompt obsolete;
catalog start with '${_ORAARC}';
}
EOF
#
fLog $_F2 "Executando RMAN"
#
#>>$_F2 rman nocatalog log ${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-backup.log @$_F1
>>$_F2 rman nocatalog @$_F1
#
fLog $_F2 "Apagando os arquivos temporarios"
#
# creating file with restore procedures
# get last DBID from logfile
_DBID=$(tac $_F2 | grep -m1 DBID | sed -r 's/(.*DBID=)([0-9]+)\)/\2/g')
# get last controlfile backup file name
_CTRLFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 controlfile)
_SPFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 spfile)
#
fLog $_F2 "Backup of oracle database pwfile"
# getting old pwfile name
_X=$(ls $_ORADES/*${_F4})
# deleting old pwfile
[ -f "$_X" ] && >>$_F2 rm -v $_X
# getting new pwfile
>>$_F2 cp -v $ORACLE_HOME/dbs/$_F4 $_ORADES/${An}${Me}${Di}-${Hr}${Mi}${Se}-$_F4
#
>$_ORADES/$_F3 cat << _EOF_
export ORACLE_SID=$ORACLE_SID
cp -v ${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-$_F4 $ORACLE_HOME/dbs/
rman
connect target /
set dbid $_DBID;
startup nomount;
restore controlfile to "$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl" from "$_CTRLFILE";
restore controlfile to "$ORACLE_BASE/oradata/$ORACLE_SID/control02.ctl" from "$_CTRLFILE";
restore spfile to "$ORACLE_HOME/dbs/spfile${ORACLE_SID}.ora" from "$_SPFILE";
shutdown abort;
startup mount;
restore database;
recover database;
alter database open resetlogs;
shutdown immediate;
startup
exit
_EOF_
#
[ -f $_F1 ] && >>$_F2 rm -fv $_F1
fLog $_F2 "Script Fim."
## Script End ##
