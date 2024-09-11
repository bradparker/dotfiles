add_to_cdpath () {
  local path=$1

  if [ -d "$path" ] && [[ ! "$CDPATH" == *"$path"* ]]; then
    export CDPATH="$CDPATH:$path"
  fi
}

CODE_DIR="$HOME/Code"
add_to_cdpath "$CODE_DIR"

GITHUB_CODE_DIR="$CODE_DIR/github.com"
add_to_cdpath "$GITHUB_CODE_DIR"

TLW_CODE_DIR="$GITHUB_CODE_DIR/thelookoutway"
add_to_cdpath "$TLW_CODE_DIR"
