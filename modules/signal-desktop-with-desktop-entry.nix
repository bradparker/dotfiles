{ config, lib, pkgs, ... }:
let
  cfg = config.programs.signal-desktop-with-desktop-entry;
  signal-desktop = pkgs.signal-desktop;
in
with lib;
{
  options = {
    programs.signal-desktop-with-desktop-entry = {
      enable = mkEnableOption "Signal with desktop entry";
    };
  };

  config = mkIf cfg.enable ({
    home.packages = [ signal-desktop ];
    home.file.".local/share/applications/signal-desktop.desktop".source = "${signal-desktop}/share/applications/signal-desktop.desktop";
  });
}
