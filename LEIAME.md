# oracle-db-backup

Script que faz backup do banco de dados Oracle usando RMAN.

Os comandos RMAN do script foram construídos entre pesquisas na internet e a maior parte consultando o docs.oracle.com "Backup and Recovery User's Guide"



Histórico
Versao______  Autor_______  Observações________________________________________
202307210940  Marcos Braga  +Terceira copia compactada do backup para enviar 
                            para a nuvem.
                            +Apaga backups antigos da segunda copia.
202307201730  Marcos Braga  +Adicionado data ao arquivo de restauracao.
202302120920  Marcos Braga  O script foi remodelado para fazer backup full e
                            incremental.
202107231228  Marcos Braga  Ajuste de variáveis globais.
