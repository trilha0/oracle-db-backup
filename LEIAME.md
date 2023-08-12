# oracle-db-backup

Script que faz backup do banco de dados Oracle usando RMAN.

Os comandos RMAN do script foram construídos entre pesquisas na internet e a maior parte consultando o docs.oracle.com "Backup and Recovery User's Guide"

Antes de começar, é importante editar o script e definir alguns parâmetros para o funcionamento do backup.

Parâmetros:
_ORADES
Esse parâmetro

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


Histórico
Versao______  Autor_______  Observações________________________________________
202307210940  Marcos Braga  +Terceira copia compactada do backup para enviar 
                            para a nuvem.
                            +Apaga backups antigos da segunda copia.
202307201730  Marcos Braga  +Adicionado data ao arquivo de restauracao.
202302120920  Marcos Braga  O script foi remodelado para fazer backup full e
                            incremental.
202107231228  Marcos Braga  Ajuste de variáveis globais.
