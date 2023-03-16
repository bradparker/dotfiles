source_nix_env () {
  local multi_user_nix_profile_env="/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
  local single_user_nix_profile_env="$HOME/.nix-profile/etc/profile.d/nix.sh"

  if [ -f $multi_user_nix_profile_env ]; then
    . $multi_user_nix_profile_env
  elif [ -f $single_user_nix_profile_env ]; then
    . $single_user_nix_profile_env
  fi
}

source_nix_env
