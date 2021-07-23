#!/bin/bash
# version=202107231228
# author=Marcos Braga | braga.marcos at gmail.com
# date=2019-10-19
# script=backup-db.sh
#
# Version_____ Author______ Notes______________________________________________
# 202107231228 marcos braga Ajust some global variables
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
export FILEFNC="<PATH>/funcoes.mab"
#
##########
# If you have not sure about what you're doing, please don't
# change the script from this point
##########
#
# Validating the variables
[ -z $_ORADES ]     && echo -e "\nFalta Editar o Script, ver linha 10\n"             && exit 1
[ -z $_ARCDIAS ]    && echo -e "\nFalta Editar o Script, ver linha 14\n"             && exit 1
[ -z $_ORAARC ]     && echo -e "\nFalta Editar o Script, ver linha 18\n"             && exit 1
[ -z $ORACLE_SID ]  && echo -e "\nFalta Editar o Script, ver linha 22\n"             && exit 1
[ -z $ORACLE_BASE ] && echo -e "\nFalta Editar o Script, ver linha 26\n"             && exit 1
[ -z $ORACLE_HOME ] && echo -e "\nFalta Editar o Script, ver linha 30\n"             && exit 1
[ -f $FILEFNC ]     && echo -e "\nArquivo de Funcoes nao encontrado, ver linha 34\n" && exit 1
# path
export PATH=$ORACLE_HOME/bin:$PATH
#
# Script Start...
FILERAW=${0%'.'*}
FILERMN=$FILERAW.rman
FILELOG=$FILERAW.log
FILEREC=restaura-db.leiame
FILEPWD=orapw${ORACLE_SID}
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
. $FILEFNC
#
# executing logfile rotate
[ -f "$" ] && rotateLog $FILELOG
#
# registrando tudo...
fLog $FILELOG "Script Inicio..."
#
fLog $FILELOG "Criando arquivo com os comandos rman"
#
>$FILERMN cat <<EOF
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
fLog $FILELOG "Executando RMAN"
#
#>>$FILELOG rman nocatalog log ${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-backup.log @$FILERMN
>>$FILELOG rman nocatalog @$FILERMN
#
fLog $FILELOG "Apagando os arquivos temporarios"
#
# creating file with restore procedures
# get last DBID from logfile
_DBID=$(tac $FILELOG | grep -m1 DBID | sed -r 's/(.*DBID=)([0-9]+)\)/\2/g')
# get last controlfile backup file name
_CTRLFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 controlfile)
_SPFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 spfile)
#
fLog $FILELOG "Backup of oracle database pwfile"
# getting old pwfile name
_X=$(ls $_ORADES/*${FILEPWD})
# deleting old pwfile
[ -f "$_X" ] && >>$FILELOG rm -v $_X
# getting new pwfile
>>$FILELOG cp -v $ORACLE_HOME/dbs/$FILEPWD $_ORADES/${An}${Me}${Di}-${Hr}${Mi}${Se}-$FILEPWD
#
>$_ORADES/$FILEREC cat << _EOF_
export ORACLE_SID=$ORACLE_SID
cp -v ${_ORADES}/${An}${Me}${Di}-${Hr}${Mi}${Se}-$FILEPWD $ORACLE_HOME/dbs/
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
[ -f $FILERMN ] && >>$FILELOG rm -fv $FILERMN
fLog $FILELOG "Script Fim."
## Script End ##
