{ config, lib, pkgs, ... }:
let
  secrets = (import /etc/nixos/secrets.nix);
  commons = {
    activeContainers = [
      "prometheus"
      "grafana"
      "postgres"
      "miniflux"
      "mosquitto"
      "matterbridge"
      "metro-bieszczady-radio"
      "thelounge"
      "mastodont"
      "ttrss"
    ];
    ips = {
      gateway     = "192.168.7.1";
      prometheus  = "192.168.7.3";
      grafana     = "192.168.7.4";
      postgres    = "192.168.7.5";
      miniflux    = "192.168.7.6";
      mosquitto   = "192.168.7.11";
      owncast     = "192.168.7.30";
      quassel     = "192.168.7.31";
      metro-bieszczady-radio = "192.168.7.32";
      matterbridge = "192.168.7.33";
      thelounge = "192.168.7.34";
      mastodont = "192.168.7.35";
      ttrss = "192.168.7.36";
    };
    domains = {
      grafana = "grafana.koguma.iscute.ovh";
      miniflux = "miniflux.koguma.iscute.ovh";
      mosquitto = "mqtt.koguma.iscute.ovh";
      owncast = "owncast.koguma.iscute.ovh";
      thelounge = "lounge.koguma.iscute.ovh";
      ttrss = "ttrss.koguma.iscute.ovh";
    };
    postgresqlPackage = pkgs.postgresql_11;
  };
  baseContainer = name: contents: lib.mkIf (builtins.elem name commons.activeContainers) ({
    timeoutStartSec = "2min";
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
  } // contents);
  baseContainerConfig = { name, dns ? false, tcp ? [], udp ? [], ... }: config:
    assert !(config?networking);
    assert !(config?nixpkgs);
    config // {
      nixpkgs.pkgs = pkgs;
      networking = {
        defaultGateway = commons.ips.gateway;
        nameservers = if dns then [ "1.1.1.1" ] else [];
        firewall = {
          allowedTCPPorts = tcp;
          allowedUDPPorts = udp;
        };
        interfaces.eth0.ipv4.addresses = [ { address = commons.ips.${name}; prefixLength = 24; } ];
      };
      services = ({ services ? {}, ... }: services // {
        prometheus = ({ prometheus ? {}, ... }: prometheus // {
          exporters = ({ exporters ? {}, ... }: exporters // {
            node = ({ node ? {}, ... }: {
              enable = true;
              openFirewall = true;
              enabledCollectors = [ "systemd" ];
            } // node) exporters;
          }) prometheus;
        }) services;
      }) config;
    };
in

{
  #nixpkgs.overlays = [
  #  (import ./unstable-overlay.nix)
  #];
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./common.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
    font = null;
    splashImage = null;
  };

  networking.hostName = "koguma";
  networking.wireless.enable = false;
  time.timeZone = "Europe/Warsaw";
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["br0"];
  networking.nat.externalInterface = "enp1s0";

  networking.wireguard = {
    enable = true;
    interfaces = {
      wg4 = {
        privateKey = secrets.wireguard.wg4.privateKey;
        listenPort = 51820;
        ips = ["192.168.4.2/24"];
        peers = [
          { allowedIPs = ["192.168.4.0/24" "192.168.2.0/24"]; publicKey = "c0LC/vDZXmeJtcqDQ9eLUxHhNJTeluUhvesYgwhzGVI="; }
          { allowedIPs = ["192.168.4.4"]; publicKey = "RIL7drX5h+tLUbnEa7uxYjA5JGlh7BerlIX1uWuZBAg="; }
          { allowedIPs = ["192.168.4.5"]; publicKey = "GKE6Pyi/3EGg1NuyWgQlVbXMCp7YW7bPz0FA+2vbflM="; }
        ];
      };
    };
  };

  networking.bridges.br0 = { interfaces = []; };
  networking.interfaces.br0 = { ipv4.addresses = [ { address = "${commons.ips.gateway}"; prefixLength = 24; } ]; };

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
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [ "systemd" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 113 ];
  networking.firewall.logRefusedConnections = false;
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  virtualisation.lxd.enable = true;
  virtualisation.lxd.recommendedSysctlSettings = true;
  virtualisation.lxc.lxcfs.enable = true;

  systemd.services."container@quassel".after = [ "container@postgres.service" ];
  systemd.services."container@miniflux".after = [ "container@postgres.service" ];

  containers.grafana = baseContainer "grafana" {
    config = { config, ... }: baseContainerConfig { name = "grafana"; dns = true; tcp = [3000]; } {
      services.grafana = {
        enable = true;
        addr = "0.0.0.0";
        domain = commons.domains.grafana;
        rootUrl = "https://${commons.domains.grafana}/";
        security.adminUser = "michcioperz";
        provision = {
          enable = true;
          datasources = [
            {
              name = "prometheus";
              type = "prometheus";
              url = "http://${commons.ips.prometheus}:9090";
            }
          ];
        };
      };
    };
  };

  containers.matterbridg = baseContainer "matterbridge" {
    config = { config, ... }: baseContainerConfig { name = "matterbridge"; dns = true; } {
      services.matterbridge = {
        enable = true;
        configFile = ''
        [irc]
          [irc.pirc]
          Server = "irc.pirc.pl:6697"
          Charset = "utf-8"
          UseTLS = true
          UseSASL = false
          Nick = "ririna"
          MessageDelay = 1300
          MessageQueue = 30
          MessageLength = 400
          MessageSplit = false
          RejoinDelay = 1
          ColorNicks = false
          Label = ""
          RemoteNickFormat = "[{PROTOCOL}] <{NOPINGNICK}> "
          ShowJoinPart = true
          ShowTopicChange = true
          RunCommands = [ "MODE ririna +B" ]
        [xmpp]
          [xmpp.junkcc]
          Server = "junkcc.net"
          Jid = "ririna@junkcc.net"
          Password = "${secrets.matterbridge.junkccPassword}"
          Muc = "chat.junkcc.net"
          Nick = "ririna"
          RemoteNickFormat = "[{PROTOCOL}] <{NOPINGNICK}> "
        [telegram]
          [telegram.ririna]
          Token = "${secrets.matterbridge.ririnaTelegramToken}"
          MessageFormat = ""
          UseFirstName = false
          UseInsecureURL = false
          QuoteDisable = false
          QuoteFormat = "{MESSAGE} (re @{QUOTENICK}: {QUOTEMESSAGE})"
          EditDisable = false
          EditSuffix = " (edited)"
          Label = ""
          RemoteNickFormat = "[{PROTOCOL}] <{NOPINGNICK}> "
          ShowJoinPart = true
          StripNick = false
          ShowTopicChange = true
        [general]
        [[gateway]]
        name = "spoldzielnia-mieszkaniowa"
        enable = true
          [[gateway.inout]]
          account = "irc.pirc"
          channel = "${secrets.matterbridge.mieszkanieIrcChannel}"
          [[gateway.inout]]
          account = "telegram.ririna"
          channel = "${secrets.matterbridge.mieszkanieTelegramChat}"
        [[gateway]]
        name = "fedipol"
        enable = true
          [[gateway.inout]]
          account = "irc.pirc"
          channel = "#fedipol"
          [[gateway.inout]]
          account = "xmpp.junkcc"
          channel = "fedipol"
        '';
      };
    };
  };

  containers.metro-radio = baseContainer "metro-bieszczady-radio" {
    config = { config, ... }: baseContainerConfig { name = "metro-bieszczady-radio"; } {
      users.users.metro-bieszczady-radio = { isSystemUser = true; };
      systemd.services.metro-bieszczady-radio = {
        wantedBy = ["default.target"];
        script = ''
          ${pkgs.python3.withPackages(ps: [ps.paho-mqtt])}/bin/python3 banalBackend.py
        '';
        environment = {
          MQTT_TRANSPORT = "tcp";
          MQTT_USER = "metrobieszczady";
          MQTT_PASSWORD = secrets.mosquitto.metrobieszczadyPassword;
          MQTT_HOST = "${commons.ips.mosquitto}";
          MQTT_PORT = "1883";
        };
        serviceConfig = {
          User = "metro-bieszczady-radio";
          Group = "nogroup";
          Restart = "always";
          RestartSec = "15";
          WorkingDirectory = "${pkgs.metro-bieszczady-frontend.src}";
        };
      };
    };
  };

  containers.miniflux = baseContainer "miniflux" {
    config = { config, lib, ... }: baseContainerConfig { name = "miniflux"; tcp = [8080]; dns = true; } {
      services.miniflux = {
        enable = true;
        config = lib.mkForce {
          DATABASE_URL = "user=miniflux dbname=miniflux sslmode=disable host=${commons.ips.postgres}";
          PORT = "8080";
          BASE_URL = "https://${commons.domains.miniflux}/";
          METRICS_COLLECTOR = "1";
          METRICS_ALLOWED_NETWORKS = "${commons.ips.prometheus}/32";
          RUN_MIGRATIONS = "1";
        };
      };
      services.postgresql.enable = lib.mkForce false;
      services.postgresql.package = commons.postgresqlPackage;
      systemd.services.miniflux-dbsetup = lib.mkForce {};
      systemd.services.miniflux = {
        requires = lib.mkForce [];
        after = lib.mkForce [ "network.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          ExecStartPre = lib.mkForce "";
        };
      };
    };
  };

  containers.mosquitto = baseContainer "mosquitto" {
    config = { config, ... }: baseContainerConfig { name = "mosquitto"; tcp = [ 1883 9001 ]; } {
      services.mosquitto = {
        enable = true;
        host = "0.0.0.0";
        port = 1883;
        checkPasswords = true;
        users = {
          public = {
            acl = [ "topic read metro-bieszczady/tracks" ];
            password = "public";
          };
          metrobieszczady = {
            acl = [ "topic write metro-bieszczady/tracks" ];
            password = secrets.mosquitto.metrobieszczadyPassword;
          };
        };
        extraConf = ''
          listener 9001 0.0.0.0
          protocol websockets
        '';
      };
    };
  };

  security.acme = {
    email = "acme.koguma@iscute.ovh";
    acceptTerms = true;
    certs."michci.ooo" = {
      extraDomainNames = ["*.michci.ooo"];
      dnsProvider = "ovh";
      credentialsFile = "/etc/nixos/michci.ooo.creds";
      webroot = pkgs.lib.mkForce null;
    };
  };
  services.nginx = {
    enable = true;
    enableReload = true;
    package = pkgs.nginxMainline;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    statusPage = true;
    virtualHosts = {
      "cutememe.iscute.ovh" = {
        enableACME = true;
        addSSL = true;
        locations."/" = {
          root = let
            cutememe = pkgs.stdenv.mkDerivation {
              name = "cutememe";
              src = ./cutememe.tar;
              buildPhase = "";
              installPhase = ''
                mkdir -p $out
                cp -r * $out/
              '';
            };
          in "${cutememe}";
          extraConfig = ''add_header Cache-Control "public, immutable, max-age=604800"; autoindex on;'';
        };
        locations."/aoba/" = {
          return = ''410 "nope"'';
          extraConfig = ''default_type text/plain;'';
        };
      };
      "project.michci.ooo" = {
        forceSSL = true;
        useACMEHost = "michci.ooo";
        serverName = "~(?<project>[a-z0-9-]+).michci.ooo";
        extraConfig = ''disable_symlinks off;'';
        locations."/" = {
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/project/$project";
        };
      };
      "michci.ooo" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          root = pkgs.writeTextDir "index.html"  ''
          '';
        };
      };
      "meekchopp.es" = {
        serverAliases = [ "www.meekchopp.es" ];
        enableACME = true;
        forceSSL = true;
        default = true;
        locations."/" = {
          root = let
            disambiguationSite = pkgs.writeTextDir "index.html" ''
              <html>
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width">
                  <title>Michcioperz</title>
                </head>
              <body>
                <h1>Michcioperz</h1>
                <ul>
                  <li><a href="https://michcioperz.com">English</a></li>
                  <li><a href="https://ijestfajnie.pl">Polski</a></li>
                </ul>
              </body>
            </html>'';
          in "${disambiguationSite}";
        };
      };
      "michcioperz.com" = {
        serverAliases = [ "www.michcioperz.com" ];
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/meekchoppes/en";
        };
        locations."/assets/" = {
          extraConfig = ''add_header Cache-Control "public, immutable, max-age=604800";'';
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/meekchoppes/en";
        };
      };
      "ijestfajnie.pl" = {
        serverAliases = [ "www.ijestfajnie.pl" ];
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/meekchoppes/pl";
        };
        locations."/assets/" = {
          extraConfig = ''add_header Cache-Control "public, immutable, max-age=604800";'';
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/meekchoppes/pl";
        };
      };
      "metro.bieszczady.pl" = {
        serverAliases = [ "www.metro.bieszczady.pl" ];
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          root = "/nix/var/nix/profiles/per-user/nginx/michciooo/share/metro-bieszczady-frontend";
        };
        locations."/.well-known/webfinger" = {
          return = "301 https://mastodon.metro.bieszczady.pl$request_uri";
        };
      };
      "mastodon.metro.bieszczady.pl" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.mastodont}:80";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 128m;
          '';
        };
      };
      "${commons.domains.thelounge}" = lib.mkIf (builtins.elem "thelounge" commons.activeContainers) {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.thelounge}:9000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_read_timeout 1d;
            client_max_body_size 10m;
          '';
        };
      };
      "${commons.domains.mosquitto}" = {
        enableACME = true;
        addSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.mosquitto}:9001";
          proxyWebsockets = true;
        };
      };
      "${commons.domains.grafana}" = lib.mkIf (builtins.elem "grafana" commons.activeContainers) {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.grafana}:3000";
        };
      };
      "${commons.domains.miniflux}" = lib.mkIf (builtins.elem "miniflux" commons.activeContainers) {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.miniflux}:8080";
        };
      };
      "${commons.domains.owncast}" = lib.mkIf (builtins.elem "owncast" commons.activeContainers) {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.owncast}:8080";
          proxyWebsockets = true;
        };
      };
      "${commons.domains.ttrss}" = lib.mkIf (builtins.elem "ttrss" commons.activeContainers) {
              enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${commons.ips.ttrss}:80";
        };
      };
    };
  };

  containers.owncast = baseContainer "owncast" {
    config = { config, ... }: baseContainerConfig { name = "owncast"; tcp = [ 1935 8080 ]; dns = true; } {
      users.users.owncast = { isSystemUser = true; };
      systemd.services.owncast = {
        wantedBy = ["default.target"];
        path = [ pkgs.ffmpeg pkgs.bash pkgs.which ];
        script = ''
          ${pkgs.owncast}/bin/owncast -database /var/lib/owncast/owncast.db
        '';
        preStart = ''
          cp --no-preserve=mode -r ${pkgs.owncast.src}/* /var/lib/owncast/
        '';
        serviceConfig = {
          User = "owncast";
          Group = "nogroup";
          Restart = "always";
          RestartSec = "15";
          StateDirectory = ["owncast"];
          WorkingDirectory = "/var/lib/owncast";
        };
      };
    };
  };

  containers.postgres = baseContainer "postgres" {
    config = { config, lib, ... }: baseContainerConfig { name = "postgres"; tcp = [5432]; } {
      services.postgresql = let pgservices = [ "miniflux" "quassel" "mastodont" "ttrss" ]; in {
        enable = true;
        package = commons.postgresqlPackage;
        enableTCPIP = true;
        ensureDatabases = pgservices;
        ensureUsers = map (name: { name = name; ensurePermissions = { "DATABASE ${name}" = "ALL PRIVILEGES"; }; }) pgservices;
        authentication = lib.strings.concatMapStringsSep "\n" (name: "host ${name} ${name} ${commons.ips."${name}"}/32 trust") pgservices;
        settings = {
          shared_preload_libraries = "pg_stat_statements";
          "pg_stat_statements.track" = "all";
        };
      };
      services.prometheus.exporters.postgres = {
        enable = true;
        openFirewall = true;
        runAsLocalSuperUser = true;
      };
    };
  };

  containers.prometheus = baseContainer "prometheus" {
    config = { config, ... }: baseContainerConfig { name = "prometheus"; tcp = [9090]; } {
      services.prometheus = {
        enable = true;
        port = 9090;
        scrapeConfigs = [
          #TODO: raspi
          {
            job_name = "node";
            static_configs = [ { targets = map (ip: commons.ips.${ip} + ":9100") ([ "gateway" ] ++ commons.activeContainers); } ];
          }
          {
            job_name = "miniflux";
            static_configs = [ { targets = [ "${commons.ips.miniflux}:8080" ]; } ];
          }
        ];
      };
    };
  };

  containers.quassel = baseContainer "quassel" {
    config = { config, ... }: baseContainerConfig { name = "quassel"; dns = true; tcp = [4242]; } {
      services.quassel = {
        enable = true;
        interfaces = [ "0.0.0.0" ];
        requireSSL = false; # TODO
      };
    };
  };

  containers.thelounge = baseContainer "thelounge" {
    forwardPorts = [
      { containerPort = 113; hostPort = 113; protocol = "tcp"; }
    ];
    config = { config, ... }: baseContainerConfig { name = "thelounge"; dns = true; tcp = [9000 113]; } {
      services.thelounge = {
        enable = true;
        private = true;
        extraConfig = {
          reverseProxy = true;
          maxHistory = -1;
          fileUpload = {
            enable = true;
            identd = {
              enable = true;
            };
          };
        };
      };
    };
  };

  containers.ttrss = baseContainer "ttrss" {
    config = { config, ... }: baseContainerConfig { name = "ttrss"; dns = true; tcp = [ 80 ]; } {
      services.postgresql.package = commons.postgresqlPackage;
      services.tt-rss = {
        enable = true;
        database = {
          createLocally = false;
          host = commons.ips.postgres;
          name = "ttrss";
          password = null;
          type = "pgsql";
          user = "ttrss";
        };
        logDestination = "syslog";
        pubSubHubbub.enable = true;
        selfUrlPath = "https://${commons.domains.ttrss}";
        virtualHost = commons.domains.ttrss;
      };
    };
  };
}

