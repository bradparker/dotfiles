add_to_cdpath () {
  local path=$1

  if [ -d "$path" ] && [[ ! "$CDPATH" == *"$path"* ]]; then
    export CDPATH="$CDPATH:$path"
  fi
}

CODE_DIR="$HOME/Code"
add_to_cdpath "$CODE_DIR"

ABC_CODE_DIR="$CODE_DIR/ABC"
add_to_cdpath "$ABC_CODE_DIR"
