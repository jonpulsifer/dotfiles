{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./home.nix
  ];

  xdg.configFile."systemd/user/cros-garcon.service.d/override.conf".source =
    ./modules/cros-garcon-override.conf;
}
