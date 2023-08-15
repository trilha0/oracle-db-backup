#!/bin/bash
#------------------------------------------------------------------------------
# Testando variaveis necessaria para o funcionamento do backup e do script
if [[ -z "$ORACLE_SID" || -z "$ORACLE_BASE" || -z "$ORACLE_HOME" ]]; then
  echo -e "\nUma das variáveis: ORACLE_BASE, ORACLE_HOME ou ORACLE_SID não encontrada.\nExecute \". oraenv\" para carregar as variáveis Oracle antes de executar esse script de instalação.\n"
  exit 1
fi
echo -e "\n
install-ora-backup.sh 1.0\n
Esse script simples para bancos de dados Oracle em modo standalone (uma 
instância) que faz backup Full do banco de dados, do Controlfile, do SPFile e 
do PasswordFile\n
Para as próximas perguntas, pressionar [ENTER] aceitará a opção padrão 
apresentada.\n"
sleep 3s
#------------------------------------------------------------------------------
# Definindo variaváis que serão usadas no decorrer do script
BKPRMANDESTINO=""       # Diretório de destino do backup RMAN
BKPRMANCOPIAS=0         # Quantidade de cópias do backup para outro local
BKPRMANCOPIASC="S"      # A cópia do backup será compactada
BKPRMANTIPO="F"         # Tipo do backup: full / full+incremental
BKPRMANARCHIVE="N"      # Backup dos archive logs
BKPRMANDIAS=5           # Tempo de retenção
BKPCOPIADESTINO=""      # Diretório(s) da(s) cópia(s) do(s) backup(s)
SN="N"                  # Opção de Sim ou Não
#------------------------------------------------------------------------------
# Aplicações que serão usadas
RMAN=$ORACLE_HOME/bin/rman
TAR=/usr/bin/tar
#------------------------------------------------------------------------------
# Diretório destino do backup
read -p "Diretório destino do backup \"[$ORACLE_BASE/backup-rman/$ORACLE_SID]\": " BKPRMANDESTINO
[ -z "$BKPRMANDESTINO" ] && BKPRMANDESTINO="$ORACLE_BASE/backup-rman/$ORACLE_SID"
echo BKPRMANDESTINO=$BKPRMANDESTINO
if [ ! -d "$BKPRMANDESTINO" ]; then
  echo -e "\nO diretório destino do backup deve existir, favor verificar.\n"
  exit 1
fi
#------------------------------------------------------------------------------
# Cópias do backup para outro local
read -p "Será feita cópia do backup para outro local? [s/N]: " SN
if [ -n "$SN" ]; then
  if [[ "$SN" -eq "s" || "$SN" -eq "S" ]]; then
    read -p "Quantas cópias do backup para outros diretórios/destinos? [1]: " BKPRMANCOPIAS
    [ -z "$BKPRMANCOPIAS" ] && BKPRMANCOPIAS=1
    echo BKPRMANCOPIAS=$BKPRMANCOPIAS
    read -p "A cópia será compactada? [s/N]: " BKPRMANCOPIASC
    [ -z "$BKPRMANCOPIASC" ] && BKPRMANCOPIASC="N"
    echo BKPRMANCOPIASC=$BKPRMANCOPIASC
    if [ $BKPRMANCOPIAS -gt 0 ]; then
      for (( i=0;i<$BKPRMANCOPIAS;i++ )); do
        read -p "Diretório $((i+1)) para cópia do backup: " BKPCOPIADESTINO[$i]
        ### Validar o diretório destino da cópia do backup
        echo BKPCOPIADESTINO[$i]=${BKPCOPIADESTINO[i]}
      done
    fi
  fi
fi
#------------------------------------------------------------------------------
# Backup full ou full + incremental
echo "
O backup será:
1. Full (*)
2. Full + Incremental
Opção: "
read BKPRMANTIPO
[ -z "$BKPRMANTIPO" ] && BKPRMANTIPO=1
echo BKPRMANTIPO=$BKPRMANTIPO
# Tempo de retenção
read -p "Quantos dias o backup será mantido (tempo de retenção)? [5]: " BKPRMANDIAS
[ -z "$BKPRMANDIAS" ] && BKPRMANDIAS=5
echo BKPRMANDIAS=$BKPRMANDIAS
#------------------------------------------------------------------------------
# Backup dos archive logs
read -p "Será feito backup dos Archive Logs? [s/N]: " BKPRMANARCHIVE
[ -z "$BKPRMANARCHIVE" ] && BKPRMANARCHIVE="N"
echo BKPRMANARCHIVE=$BKPRMANARCHIVE
#------------------------------------------------------------------------------
# 

#------------------------------------------------------------------------------
# Conectando no RMAN
rmanConnect() {
  echo "connect target /" 
}
#------------------------------------------------------------------------------
# Desconectando do RMAN
rmanDisconnect() {
  echo "exit"
}
#------------------------------------------------------------------------------
# RMAN Inicia um bloco
rmanRunStart() {
  echo "run {"
}
#------------------------------------------------------------------------------
# RMAN Finaliza um bloco
rmanRunEnd() {
  echo "}"
}

#------------------------------------------------------------------------------
# Definindo as configurações escolhidas no RMAN
# Oracle Database 21c
# RMAN configuration parameters for database are:
#
# CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
# CONFIGURE BACKUP OPTIMIZATION OFF; # default
# CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
# CONFIGURE CONTROLFILE AUTOBACKUP ON; # default
# CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
# CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
# CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
# CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default

# CONFIGURE MAXSETSIZE TO UNLIMITED; # default
# CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
# CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
# CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
# CONFIGURE RMAN OUTPUT TO KEEP FOR 7 DAYS; # default
# CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
# CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/opt/oracle/dbs/snapcf_XE.f'; # default
#
rmanConfigure() {
  echo "configure retention policy to recovery window of $BKPRMANDIAS day;
configure backup optimization on;
configure controlfile autobackup off;

configure archivelog deletion policy to none;
crosscheck backup;
crosscheck archivelog all;
configure default device type to disk;"
}
#------------------------------------------------------------------------------


