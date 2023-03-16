CODE_DIR="$HOME/Code"
if [ -d "$CODE_DIR" ] && $(echo "$CDPATH" | grep -v "/home/brad/Code"); then
  export CDPATH="$CDPATH:$CODE_DIR"
fi
