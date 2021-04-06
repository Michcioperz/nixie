{ config, pkgs, ... }:
let secrets = (import /etc/nixos/secrets.nix); in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ./nixos-hardware/lenovo/thinkpad/x230
      ./nixos-hardware/common/pc/ssd
      ./common.nix
    ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.grub = {
    device = "/dev/sda";
    memtest86.enable = true;
    useOSProber = true;
  };
  boot.plymouth.enable = true;
  boot.supportedFilesystems = [ "cifs" ];
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
    mupdf pcmanfm xarchiver unzip file xclip ncdu jq ldns sshfs
    python3 nodejs rustc cargo rustfmt go direnv
    lsd ripgrep tokei fd bat gitAndTools.delta httplz
    pass pass-otp git gnupg watchman
    ncspot mpv youtube-dl strawberryProprietary ffmpeg-full
    quasselClient tdesktop mumble pavucontrol bitwarden bitwarden-cli
    firefoxNoGtkTheme transmission-qt thunderbird
    antibody workrave cargo-edit gimp pulseaudio feh ffmpeg git-cola gnome3.meld
    hicolor-icon-theme gnome3.adwaita-icon-theme gtk-engine-murrine gtk_engines gsettings-desktop-schemas lxappearance
    python3Packages.black python3Packages.jedi
  ] ++ [ lutris libreoffice blender obs-studio ghostwriter projectm bitwarden ];
  environment.variables = {
    GTK_THEME = "Adwaita-dark";
    RUST_SRC_PATH = ''${pkgs.stdenv.mkDerivation {
      inherit (pkgs.rustc) src;
      inherit (pkgs.rustc.src) name;
      phases = ["unpackPhase" "installPhase"];
      installPhase = "cp -r library $out";
      preferLocalBuild = true;
      allowSubstitutes = false;
    }}'';
  };
  fileSystems."/home/michcioperz/t" = {
    device = "//192.168.2.4/media";
    fsType = "cifs";
    options = [ "rw" "vers=1.0" "guest" "uid=1000" "forceuid" "dir_mode=0755" "file_mode=0644" "noposix" "x-systemd.automount" "x-systemd.idle-timeout=60" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s" "noauto" ];
  };
  fileSystems."/home/michcioperz/backup" = {
    device = "//192.168.2.4/backup";
    fsType = "cifs";
    options = [ "rw" "vers=1.0" "guest" "uid=1000" "noposix" "x-systemd.automount" "x-systemd.idle-timeout=60" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s" "noauto" ];
  };
  fonts = {
    fonts = with pkgs; [
      fantasque-nerdfont overpass-nerdfont overpass merriweather lato comic-relief
    ];
    fontconfig.defaultFonts = {
      monospace = ["FantasqueSansMono Nerd Font"];
      sansSerif = ["Overpass"];
      serif = ["Merriweather"];
    };
  };
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
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
  services.picom = {
    vSync = true;
    # fade = true;
    shadow = true;
    enable = true;
  };
  i18n.defaultLocale = "en_GB.UTF-8";
  location.latitude = 52.;
  location.longitude = 21.;
  networking.firewall.allowedTCPPorts = [ 8000 8001 9091 51413 ];
  networking.firewall.allowedUDPPorts = [ 51413 ];
  networking.hostName = "x225";
  networking.useDHCP = false;
  #networking.nat = {
  #  enable = true;
  #  externalInterface = "enp0s26u1u2";
  #  internalIPs = ["192.168.1.0/24"];
  #};
  networking.networkmanager.enable = true;
  networking.wireguard.enable = false;
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
  nix.useSandbox = true;
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
    extraGroups = [ "wheel" "networkmanager" "dialout" "nitrokey" "lxd" ];
  };
  users.users.builder = {
    isNormalUser = true;
  };
  virtualisation.lxc.lxcfs.enable = true;
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true;
  };
  system.stateVersion = "20.09";
}
