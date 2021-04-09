{ config, pkgs, ... }:

{
  nixpkgs.overlays = [ (import ./unstable-overlay.nix) ];
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./common.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "koguma";
  networking.wireless.enable = false;
  time.timeZone = "Europe/Warsaw";
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "pl";
  };

  users.users.michcioperz = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [ git tmux neovim htop ];

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

