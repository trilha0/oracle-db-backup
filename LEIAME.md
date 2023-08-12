# oracle-db-backup

Script que faz backup do banco de dados Oracle usando RMAN.

Os comandos RMAN do script foram construídos entre pesquisas na internet e a maior parte consultando o docs.oracle.com "Backup and Recovery User's Guide"

Antes de começar, é importante editar o script e definir alguns parâmetros para o funcionamento do backup.

Parâmetros --------------------------------------------------------------------
_ORADES
Esse parâmetro indica um ou mais caminhos para onde o backup será copiado. É 
possível adicionar mais caminhos separados por espaço, dentro do parênteses 
"()". Ex.
_ORADES=(/caminho/1 /caminho/2)

_ARCDIAS
Parâmetro que define o número de dias em que os _archives_ (redo logs 
arquivados) do banco de dados serão mantidos.

_ORAARC
Parâmetro que indica qual é o diretório onde os _archives_ do banco de dados 
são gravados.

ORACLE_SID
Parâmetro que indica o nome do banco de dados

ORACLE_BASE
Parâmetro que indica o caminho base de instalação do banco de dados.

ORACLE_HOME
Parâmetro que indica o caminho de instalação do banco de dados.

FILEFNC
Parâmetro que indica o caminho onde o arquivo de funções está localizado.


Histórico ---------------------------------------------------------------------
Versao______  Autor_______  Observações________________________________________
202307210940  Marcos Braga  +Terceira copia compactada do backup para enviar 
                            para a nuvem.
                            +Apaga backups antigos da segunda copia.
202307201730  Marcos Braga  +Adicionado data ao arquivo de restauracao.
202302120920  Marcos Braga  O script foi remodelado para fazer backup full e
                            incremental.
202107231228  Marcos Braga  Ajuste de variáveis globais.
-------------------------------------------------------------------------------
