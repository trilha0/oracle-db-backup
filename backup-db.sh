#!/bin/bash
# version..: 202307210940
# author...: Marcos Braga | braga.marcos at gmail.com
# created..: 2019-10-19
# script...: backup-db.sh
#
#------------------------------------------------------------------------------
# Adicionar o caminho de destino dos arquivos de backup
# 1 = Backup principal; 2 = Copia do backup; 3 = Copia do backup para nuvem.
export _ORADES=(/dir/path1 /dir/path2 /dir/path3)
#------------------------------------------------------------------------------
# Quantos dias manter archives no disco
export _ARCDIAS=7
#------------------------------------------------------------------------------
# Diretorio onde sao gravados os archives
export _ORAARC=/dir/path/archives
#------------------------------------------------------------------------------
# Nome do banco de dados, ORACLE_SID
export ORACLE_SID=oraclesid
#------------------------------------------------------------------------------
# Diretorio do ORACLE_BASE
export ORACLE_BASE=/dir/path/oraclebase
#------------------------------------------------------------------------------
# Diretorio do ORACLE_HOME
export ORACLE_HOME=/dir/path/oraclehome
#------------------------------------------------------------------------------
# Localizacao arquivo de funcoes
export FILEFNC=/dir/path/funcoes.mab
#------------------------------------------------------------------------------
##########
# If you have not sure about what you're doing, please don't
# change the script from this point
##########
BTYPE=${1}
case $BTYPE in
  [Ff][Uu][Ll][Ll]|0)
    BTYPE=(0 full)
    BDESC=Backup_Diario_Full
    BARCH=plus archivelog
    BCRO=
  ;;
  [Ii][Nn][Cc]|1)
    BTYPE=(1 incremental)
    BDESC=Backup_Diario_Incremental
    BARC=
    BCRO=
  ;;
  *)
    echo "Opcao Invalida."
    echo "Opcoes validas: Full ou Inc"
    exit 1
  ;;
esac
#
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
Da=$(date +%d --date="2 days ago")  # - dois dias
Hr=$(date +%H)  # hora
Mi=$(date +%M)  # minutos
Se=$(date +%S)  # segundos
#
# load functions
. $FILEFNC
#
# executing logfile rotate
[ -f "$FILELOG" ] && rotateLog "$FILELOG"
#
# registrando tudo...
fLog $FILELOG "Script Inicio - $BDESC"
#
fLog $FILELOG "Criando arquivo com os comandos rman"
#
>$FILERMN echo '
connect target /
run {'
if [ ${BTYPE[0]} = 0 ]; then
  >>$FILERMN echo 'configure controlfile autobackup off;
#configure archivelog deletion policy to shipped to standby;
configure archivelog deletion policy to none;
configure device type disk backup type to compressed backupset;
crosscheck backup;
crosscheck archivelog all;'
fi
>>$FILERMN echo "allocate channel Ch1 type disk maxpiecesize 4g format '${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}-database-backup-${BTYPE[1]}-%U';
backup incremental level ${BTYPE[0]} tag $BDESC as compressed backupset not backed up 1 times database $BARCH;
release channel Ch1;
allocate channel Ch1 type disk format '${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}-controlfile-backup-${BTYPE[1]}-%U';
backup tag Backup_Controlfile (current controlfile);
release channel Ch1;"
if [ ${BTYPE[0]} = 0 ]; then
  >>$FILERMN echo "allocate channel Ch1 type disk format '${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}-spfile-backup-${BTYPE[1]}-%U';
backup tag Backup_SPFile (spfile);
release channel Ch1;
delete noprompt expired backup;
change archivelog from time 'sysdate-${_ARCDIAS}' uncatalog;
delete noprompt obsolete;
catalog start with '${_ORAARC}';"
fi
>>$FILERMN echo '}'
#
fLog $FILELOG "Executando RMAN"
>>$FILELOG rman nocatalog @$FILERMN
#
# creating file with restore procedures
# get last DBID from logfile
_DBID=$(tac $FILELOG | grep -m1 DBID | sed -r 's/(.*DBID=)([0-9]+)\)/\2/g')
# get last controlfile backup file name
#_CTRLFILE=$(tac $FILELOG | grep -m1 controlfile-backup | sed -r 's/(.*handle=)(.*)(R.*)/\2/g')
_CTRLFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 controlfile)
_SPFILE=$_ORADES/$(ls -tR $_ORADES | grep -m1 spfile)
#
if [ ${BTYPE[0]} = 0 ]; then
  fLog $FILELOG "Backup of oracle database pwfile"
  # getting old pwfile name
  _X=$(ls $_ORADES/*${FILEPWD})
  # deleting old pwfile
  [ -f "$_X" ] && >>$FILELOG rm -v $_X
  # getting new pwfile
  >>$FILELOG cp -v $ORACLE_HOME/dbs/$FILEPWD $_ORADES/${An}${Me}${Di}-${Hr}${Mi}${Se}-$FILEPWD
fi
#
if [ ${BTYPE[0]} = 0 ]; then
  >$_ORADES/${An}${Me}${Di}-${Hr}${Mi}${Se}-$FILELEI cat << _EOF_
export ORACLE_SID=$ORACLE_SID
cp -v ${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}-$FILEPWD $ORACLE_HOME/dbs/$FILEPWD
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
fi
#
fLog $FILELOG "[COPY-JOB] Copiando o backup para um segundo local"
>>$FILELOG cp -v ${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}* ${_ORADES[1]}/
fLog $FILELOG "[COPY-JOB-CLOUD] Compactando o backup full para o diretorio da nuvem"
>>$FILELOG tar cvfzP ${_ORADES[2]}/${An}${Me}${Di}-${Hr}${Mi}${Se}-${BDESC}.tgz ${_ORADES[0]}/${An}${Me}${Di}-${Hr}${Mi}${Se}*
fLog $FILELOG "[COPY-JOB] Apagando arquivos antigos"
BKPOLD=$(ls ${_ORADES[1]}/${An}${Me}${Da}*)
fLog $FILELOG "[COPY-JOB-CLOUD] Apagando arquivos antigos"
[ -n "$BKPOLD" ] && >>$FILELOG rm -v $BKPOLD
BKPOLD=$(ls ${_ORADES[2]}/${An}${Me}${Da}*)
[ -n "$BKPOLD" ] && >>$FILELOG rm -v $BKPOLD
fLog $FILELOG "Apagando os arquivos temporarios"
[ -f $FILERMN ] && >>$FILELOG rm -fv $FILERMN
fLog $FILELOG "Script Fim - $BDESC."
## Script End ##
