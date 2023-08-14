#!/bin/bash
# Testando variaveis necessaria para o funcionamento do backup e do script
if [[ -z "$ORACLE_SID" || -z "$ORACLE_BASE" || -z "$ORACLE_HOME" ]]; then
  echo -e "\nUma das variáveis: ORACLE_BASE, ORACLE_HOME ou ORACLE_SID não encontrada.\nExecute \". oraenv\" para carregar as variáveis Oracle antes de executar esse script de instalação.\n"
  exit 1
fi
echo -e "\nPara as próximas perguntas, pressionar [ENTER] aceitará a opção padrão apresentada.\n"
sleep 4s
# Diretório destino do backup -------------------------------------------------
read -p "Diretório destino do backup \"[$ORACLE_BASE/backup-rman/$ORACLE_SID]\": " BKPRMANDESTINO
[ -z "$BKPRMANDESTINO" ] && BKPRMANDESTINO="$ORACLE_BASE/backup-rman/$ORACLE_SID"
echo BKPRMANDESTINO=$BKPRMANDESTINO
if [ ! -d "$BKPRMANDESTINO" ]; then
  echo -e "\nO diretório destino do backup deve existir, favor verificar.\n"
  exit 1
fi
read -n1 -p "Será feita cópia do backup para outro local? [s/N]: " SN
if [ -n "$SN" ]; then
  if [[ "$SN" -eq "s" || "$SN" -eq "S" ]]; then
    read -p "Quantas cópias do backup para outros diretórios/destinos [1]: " BKPRMANCOPIAS
    [ -z "$BKPRMANCOPIAS" ] && BKPRMANCOPIAS=0
    echo BKPRMANCOPIAS=$BKPRMANCOPIAS
    if [ $BKPRMANCOPIAS -gt 0 ]; then
      for ((i=1;i<=$BKPRMANCOPIAS;i++)); do
        read -p "Diretório $i para cópia do backup: " BKPRMANCOPIAS[$i]
        echo BKPRMANCOPIAS[$i]=$BKPRMANCOPIAS[$i]
      done
    fi
  fi
fi
