{ config, pkgs, ... }:
let secrets = (import /etc/nixos/secrets.nix); in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/lenovo/thinkpad/x230"
      "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/common/pc/hdd"
      ./common.nix
    ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelPackages = pkgs.linuxPackages_5_10;
  boot.loader.grub = {
    device = "/dev/sda";
    memtest86.enable = true;
    useOSProber = true;
  };
  boot.plymouth.enable = true;
  console.keyMap = "pl";
  console.colors = [ "184956" "fa5750" "75b938" "dbb32d" "4695f7" "f275be" "41c7b9" "72898f" "2d5b69" "ff665c" "84c747" "ebc13d" "58a3ff" "ff84cd" "53d6c7" "cad8d9" ];
  documentation.dev.enable = true;
  environment.shellAliases = {
    ls = "lsd";
    ll = "ls -l";
    vi = "nvim";
    ssh = "TERM=xterm ssh";
  };
  environment.systemPackages = with pkgs; [
    wget neovim-m314 htop pciutils usbutils aria
    mupdf pcmanfm xarchiver
    python3 nodejs rustc cargo rustfmt direnv
    lsd ripgrep tokei fd bat gitAndTools.delta httplz
    pass pass-otp git gnupg lutris
    ncspot mpv youtube-dl strawberryProprietary
    quasselClient tdesktop mumble pavucontrol
    firefoxNoGtkTheme libreoffice transmission-remote-gtk
    antibody workrave cargo-edit gimp
    hicolor-icon-theme gnome3.adwaita-icon-theme gtk-engine-murrine gtk_engines gsettings-desktop-schemas lxappearance
  ];
  environment.variables = {
    GTK_THEME = "Adwaita-dark";
    RUST_SRC_PATH = ''${pkgs.stdenv.mkDerivation {
      inherit (pkgs.rustc) src;
      inherit (pkgs.rustc.src) name;
      phases = ["unpackPhase" "installPhase"];
      installPhase = "cp -r library $out";
    }}'';
  };
  fonts = {
    fonts = with pkgs; [
      overpass-nerdfont overpass merriweather lato comic-relief
    ];
    fontconfig.defaultFonts = {
      monospace = ["OverpassMono Nerd Font"];
      sansSerif = ["Overpass"];
      serif = ["Merriweather"];
    };
  };
  hardware.enableRedistributableFirmware = true;
  hardware.nitrokey.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  # TODO: hardware.printers
  # TODO: hardware.sane.brscan4
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
  };
  i18n.defaultLocale = "en_GB.UTF-8";
  location.latitude = 52.;
  location.longitude = 21.;
  networking.firewall.allowedTCPPorts = [ 8000 8001 ];
  networking.hostName = "x225";
  networking.useDHCP = false;
  #networking.nat = {
  #  enable = true;
  #  externalInterface = "enp0s26u1u2";
  #  internalIPs = ["192.168.1.0/24"];
  #};
  networking.networkmanager.enable = true;
  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    wg112 = {
      ips = ["192.168.112.54/24"];
      privateKey = secrets.wg112.privateKey;
      peers = [
        {
          publicKey = "FobjzjbLfHuPiB5s1krH8IytRLoAZvPJxPxSprWWQGk=";
          allowedIPs = ["192.168.112.0/24" "192.168.0.0/24"];
          endpoint = "0x7f.one:10112";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  nix.allowedUsers = [ "root" "builder" "@wheel" ];
  nix.autoOptimiseStore = true;
  nix.buildMachines = [
    {
      hostName = "localhost";
      systems =  [ "x86_64-linux" "aarch64-linux" ];
      speedFactor = 1;
      maxJobs = 2;
      supportedFeatures = [ "nixos-test" "kvm" ];
    }
    {
      hostName = "192.168.0.64";
      system = "x86_64-linux";
      speedFactor = 2;
      maxJobs = 4;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [];
      sshUser = "builder";
      sshKey = "/root/.ssh/id_builder";
    }
  ];
  nix.distributedBuilds = true;
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
  nix.trustedUsers = [ "root" "builder" "michcioperz" ];
  nixpkgs.config.allowUnfree = true;
  programs.bandwhich.enable = true;
  programs.dconf.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.iftop.enable = true;
  programs.iotop.enable = true;
  programs.less.enable = true;
  programs.mtr.enable = true;
  programs.nm-applet.enable = true;
  programs.traceroute.enable = true;
  programs.tmux = {
    aggressiveResize = true;
    clock24 = true;
    historyLimit = 50000;
    enable = true;
  };
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  programs.zsh = {
    enable = true;
  };
  qt5 = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
  security.unprivilegedUsernsClone = true;
  # TODO: read more services
  services.fractalart = {
    enable = true;
    width = 1920;
    height = 1080;
  };
  services.gvfs.enable = true;
  services.lorri.enable = true;
  services.openssh.enable = true;
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_12;
  };
  services.printing.enable = true;
  services.redshift.enable = true;
  services.thermald.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", GROUP:="dialout"
  '';
  services.uptimed.enable = true;
  services.xserver = {
    displayManager.defaultSession = "none+i3";
    displayManager.lightdm.enable = true;
    enable = true;
    layout = "pl";
    libinput.enable = true;
    useGlamor = true;
    videoDrivers = [ "modesetting" ];
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        rofi scrot kitty i3status-rust fractalLock i3spin
      ];
    };
    xrandrHeads = [ "HDMI-1" "LVDS-1" ];
  };
  sound.enable = true;
  time.timeZone = "Europe/Warsaw";
  users.defaultUserShell = pkgs.zsh;
  users.users.michcioperz = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "dialout" "nitrokey" ];
  };
  users.users.builder = {
    isNormalUser = true;
  };
  system.stateVersion = "20.09";
}
