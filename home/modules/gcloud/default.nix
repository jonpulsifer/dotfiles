{ lib, pkgs, config, ... }:
let
  inherit (lib) mkMerge;
  components = with pkgs.google-cloud-sdk.components; [
    cloud-firestore-emulator
    cloud-run-proxy
    cloud_sql_proxy
    gke-gcloud-auth-plugin
  ];
in
{
  xdg.enable = true;
  xdg.configFile."gcloud/configurations/config_home".text = ''
    [core]
    account = jonathan@pulsifer.ca
    project = homelab-ng

    [compute]
    region = northamerica-northeast2
    zone = northamerica-northeast2-a

    [artifacts]
    location = northamerica-northeast2
    repository = i
  '';

  home.sessionVariables = {
    CLOUDSDK_CONFIG = "$HOME/.config/gcloud";
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
  };
  home.packages = with pkgs; [
    google-cloud-sql-proxy
    # nodePackages.firebase-tools
    # openjdk19
    (google-cloud-sdk.withExtraComponents components)
  ];
}
