CODE_DIR="$HOME/Code"
if [ -d "$CODE_DIR" ] && [[ ! "$CDPATH" == *"$CODE_DIR"* ]]; then
  export CDPATH="$CDPATH:$CODE_DIR"
fi
