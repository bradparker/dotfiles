BASE16_SHELL="$HOME/.config/base16-shell"
[ -n "$PS1" ] && \
  [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
    eval "$(bash "$BASE16_SHELL/profile_helper.sh")"
