{ config, pkgs, ... }:
let secrets = (import /etc/nixos/secrets.nix); in
{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./common.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    luksroot = {
      device = "/dev/disk/by-uuid/1f5b9bfb-5403-40b3-80ae-ab9a6f30138b";
      preLVM = true;
    };
  };

  networking.hostName = "hinata"; # Define your hostname.

  time.timeZone = "Europe/Warsaw";

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;
  networking.interfaces.eno3.useDHCP = true;
  networking.interfaces.eno4.useDHCP = true;

  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["br0"];
  networking.nat.externalInterface = "eno1";

  networking.bridges.br0 = { interfaces = []; };
  networking.interfaces.br0 = { ipv4.addresses = [ { address = "192.168.7.1"; prefixLength = 24; } ]; };

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "pl";
  };

  

  users.users.michcioperz = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  users.users.builder = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaGFdY+z5VfwYyrrEwKmSv3L2+cUW/KZDX8hlOSFEdX root@x225"
    ];
  };
  nix.trustedUsers = [ "root" "builder" ];

  environment.systemPackages = with pkgs; [
    wget neovim htop git tmux
  ];

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "prohibit-password";
  services.openssh.passwordAuthentication = false;

  networking.firewall.allowedTCPPorts = [ 22 80 443 6697 13370 ];
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+HtJN67TN/MaBfayXZxZfuiQjDrg53rgJht+ZTVjXt/RSyppg6xb0n0T0BdCIf9r96Rr2y0yM3JZuVlGPmgIzHfVMvApndMH3k0/pTa9vBYJvysv1O7kKwNOM10C46z+sPd67N3RPX0JhP1iSQ4hZ9RfwCMVYHpXNZ3dhVHgR+3M48W0bcrcgXOHiG1fSP+He5a7DCajfej5G5y1yo3OR1d2ZOhu4KQWotKzMWyP7Z1VYmhQwZDfBBEZ/U0UeZroiOjxKopq9NhJiosD7a5UWUEy/nTR5ZeXoDHarpgrmM03xMbcmtIZmn05vIoRLh9BeLgrStgElqUufsf3Bd1LH"
  ];

  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [ "systemd" ];
  };

  containers.nginx2 = {
    privateNetwork = true;
    hostBridge = "br0";
    forwardPorts = [
      { containerPort = 80; hostPort = 80; protocol = "tcp"; }
      { containerPort = 443; hostPort = 443; protocol = "tcp"; }
      { containerPort = 6697; hostPort = 6697; protocol = "tcp"; }
    ];
    autoStart = true;
    bindMounts = {
      "/git" = { hostPath = "/home/michcioperz/git"; isReadOnly = true; };
      "/radyj-public" = { hostPath = "/home/michcioperz/radyj-public"; isReadOnly = true; };
      "/stagit" = { hostPath = "/home/michcioperz/stagit"; isReadOnly = true; };
      "/tank" = { hostPath = "/tank"; isReadOnly = true; };
      #"/nsu" = { hostPath = "/home/michcioperz/nsu"; isReadOnly = true; };
    };
    config = { config, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      environment.etc."tank_ca.crt".text = builtins.readFile "/etc/tank_ca.crt";
      security.acme.email = "acme.hinata@iscute.ovh";
      security.acme.acceptTerms = true;
      services.nginx = {
        enable = true;
        package = pkgs.nginxMainline;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        statusPage = true;
        appendHttpConfig = ''proxy_cache_path /var/cache/nginx/radyj levels=1:2 keys_zone=radyj:10m;'';
        virtualHosts = {
          "www.metro.bieszczady.pl" = {
            enableACME = true;
            addSSL = true;
            basicAuth = { "comfy" = secrets.icecast.comfyPassword; };
            locations."/" = {
              extraConfig = ''proxy_pass_header Authorization;'';
              proxyPass = "http://192.168.7.12:8000";
            };
          };
          "0x7f.one" = {
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              ssl_client_certificate /etc/tank_ca.crt;
              ssl_verify_client optional;
            '';
            locations."/" = {
              root = "/tank";
              extraConfig = ''
                autoindex on;
                if ($ssl_client_verify != SUCCESS) {
                  return 403;
                }
              '';
            };
          };
          "grafana.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://192.168.7.4:3000";
            };
          };
          "radyj.hinata.iscute.ovh" = {
            enableACME = true;
            addSSL = true;
            locations."/" = {
              root = "/radyj-public";
            };
            locations."/api" = {
              proxyPass = "http://192.168.7.19:8000";
              extraConfig = ''add_header Cache-Control "public, immutable, max-age=3600"; proxy_cache radyj; proxy_cache_lock on; proxy_cache_revalidate off; proxy_cache_valid 1h;'';
            };
          };
          "honk.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://192.168.7.18:8000";
            };
          };
          "miniflux.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://192.168.7.6:8080";
            };
          };
          #"mqtt.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  http2 = false;
          #  locations."/" = {
          #    proxyPass = "http://192.168.7.11:15675";
          #    proxyWebsockets = true;
          #  };
          #};
          #"hydra.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  locations."/" = {
          #    proxyPass = "http://192.168.7.8:3000";
          #  };
          #};
          #"grocy.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  locations."/" = {
          #    proxyPass = "http://192.168.7.14:80";
          #  };
          #};
          "git.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."@git" = {
              root = "/git";
              extraConfig = "autoindex on;";
            };
            locations."/" = {
              index = "index.html log.html";
              root = "/stagit";
              tryFiles = "$uri $uri/ @git";
            };
            extraConfig = "add_header Cache-Control \"max-age=300, public, immutable\";";
          };
          #"michcioperz.com" = {
          #  #enableACME = true;
          #  #forceSSL = true;
          #  locations."/" = {
          #    root = "${pkgs.meekchoppes}/share/meekchoppes/en";
          #  };
          #};
          #"ijestfajnie.pl" = {
          #  #enableACME = true;
          #  #forceSSL = true;
          #  locations."/" = {
          #    root = "${pkgs.meekchoppes}/share/meekchoppes/pl";
          #  };
          #};
        };
        appendConfig = let cfg = config.services.nginx; in ''
          stream {
            upstream bitlbee {
              server 192.168.7.15:6667 max_fails=3 fail_timeout=10s;
            }
            server {
              listen 6697 ssl;
              proxy_pass bitlbee;
              proxy_next_upstream on;
              ssl_certificate ${config.security.acme.certs."0x7f.one".directory}/fullchain.pem;
              ssl_certificate_key ${config.security.acme.certs."0x7f.one".directory}/key.pem;
            }
            ssl_protocols ${cfg.sslProtocols};
            ssl_ciphers ${cfg.sslCiphers};
            # Keep in sync with https://ssl-config.mozilla.org/#server=nginx&config=intermediate
            ssl_session_timeout 1d;
            ssl_session_cache shared:SSLst:10m;
            # Breaks forward secrecy: https://github.com/mozilla/server-side-tls/issues/135
            ssl_session_tickets off;
            # We don't enable insecure ciphers by default, so this allows
            # clients to pick the most performant, per https://github.com/mozilla/server-side-tls/issues/260
            ssl_prefer_server_ciphers off;
          }
        '';
      };
      services.prometheus.exporters.nginx = {
        enable = true;
        openFirewall = true;
      };
      networking.firewall.allowedTCPPorts = [ 80 443 6697 ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.2"; prefixLength = 24; } ];
    };
  };

  containers.prometheus = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      services.prometheus = {
        enable = true;
        port = 9090;
        remoteWrite = [
          {
            url = "http://192.168.7.20:8086/api/v1/prom/write?db=prometheus";
          }
        ];
        scrapeConfigs = [
          {
            job_name = "raspi";
            static_configs = [ { targets = [ "192.168.2.13:8764" ]; } ];
            honor_labels = true;
            metrics_path = "/federate";
            params = { "match[]" = [ ''{__name__=~".*"}'' ]; };
            scrape_interval = "15s";
          }
          {
            job_name = "node";
            static_configs = [ { targets = [
              "192.168.7.1:9100"
              "192.168.7.2:9100"
              "192.168.7.3:9100"
              "192.168.7.4:9100"
              "192.168.7.5:9100"
              "192.168.7.6:9100"
              "192.168.7.7:9100"
              "192.168.7.9:9100"
              "192.168.7.11:9100"
              "192.168.7.12:9100"
              "192.168.7.13:9100"
              "192.168.7.15:9100"
              "192.168.7.18:9100"
              "192.168.7.19:9100"
              "192.168.7.20:9100"
            ]; } ];
          }
          {
            job_name = "postgres";
            static_configs = [ { targets = [ "192.168.7.5:9187" ]; } ];
          }
          {
            job_name = "miniflux";
            static_configs = [ { targets = [ "192.168.7.6:8080" ]; } ];
          }
          {
            job_name = "ipmi";
            metrics_path = "/ipmi";
            scrape_timeout = "30s";
            static_configs = [ { targets = [ "192.168.0.5" ]; } ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                separator = ";";
                regex = "(.*)";
                target_label = "__param_target";
                replacement = null;
                action = "replace";
              }
              {
                source_labels = [ "__param_target" ];
                separator = ";";
                regex = "(.*)";
                target_label = "instance";
                replacement = null;
                action = "replace";
              }
              {
                separator = ";";
                regex = ".*";
                target_label = "__address__";
                replacement = "192.168.7.7:9290";
                action = "replace";
              }
            ];
          }
        ];
      };
      networking.firewall.allowedTCPPorts = [ 9090 ];
      networking.defaultGateway = "192.168.7.1";
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.3"; prefixLength = 24; } ];
    };
  };

  containers.grafana = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      services.grafana = {
        enable = true;
        addr = "0.0.0.0";
        domain = "grafana.hinata.iscute.ovh";
        rootUrl = "https://grafana.hinata.iscute.ovh/";
        security.adminUser = "michcioperz";
      };
      networking.firewall.allowedTCPPorts = [ 3000 ];
      networking.defaultGateway = "192.168.7.1";
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.4"; prefixLength = 24; } ];
      networking.nameservers = [ "1.1.1.1" ];
    };
  };

  containers.postgres = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_11;
        enableTCPIP = true;
        ensureDatabases = [ "miniflux" "hydra" ];
        ensureUsers = [
          {
            name = "miniflux";
            ensurePermissions = { "DATABASE miniflux" = "ALL PRIVILEGES"; };
          }
          {
            name = "hydra";
            ensurePermissions = { "DATABASE hydra" = "ALL PRIVILEGES"; };
          }
        ];
        authentication = ''
          host miniflux miniflux 192.168.7.6/32 trust
          host hydra hydra 192.168.7.8/32 trust
        '';
      };
      services.prometheus.exporters.postgres = {
        enable = true;
        openFirewall = true;
      };
      networking.firewall.allowedTCPPorts = [ 5432 ];
      networking.defaultGateway = "192.168.7.1";
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.5"; prefixLength = 24; } ];
    };
  };

  containers.miniflux = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      services.miniflux = {
        enable = true;
        config = lib.mkForce {
          DATABASE_URL = "user=miniflux dbname=miniflux sslmode=disable host=192.168.7.5";
          PORT = "8080";
          BASE_URL = "https://miniflux.hinata.iscute.ovh/";
          METRICS_COLLECTOR = "1";
          METRICS_ALLOWED_NETWORKS = "192.168.7.3/32";
          RUN_MIGRATIONS = "1";
        };
      };
      systemd.services.miniflux = {
        requires = lib.mkForce [];
        after = lib.mkForce [ "network.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          ExecStartPre = lib.mkForce "" ;
        };
      };
      services.postgresql.enable = lib.mkForce false;
      services.postgresql.package = pkgs.postgresql_11;
      networking.firewall.allowedTCPPorts = [ 8080 ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.6"; prefixLength = 24; } ];
    };
  };

  containers.ipmiprom = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      environment.etc."ipmi_exporter.yml" = {
        text = ''{"modules": {"default": { "user": "${secrets.ipmi.user}", "pass": "${secrets.ipmi.pass}", "privilege": "user", "driver": "LAN_2_0", "collectors": ["bmc", "ipmi", "chassis"]}}}'';
      };
      systemd.services.ipmi-exporter = {
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          PrivateTmp = true;
          WorkingDirectory = "/tmp";
          ExecStart = ''
            ${pkgs.ipmi-exporter}/bin/ipmi_exporter \
              --web.listen-address :9290 \
              --freeipmi.path ${pkgs.freeipmi}/bin \
              --config.file /etc/ipmi_exporter.yml
          '';
        };
      };
      networking.firewall.allowedTCPPorts = [ 9290 ];
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.7"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
    };
  };

  #containers.hydra = {
  #  privateNetwork = true;
  #  hostBridge = "br0";
  #  autoStart = true;
  #  config = { config, lib, pkgs, ... }: {
  #    services.hydra = {
  #      enable = true;
  #      hydraURL = "https://hydra.hinata.iscute.ovh";
  #      notificationSender = "hydra@hinata.iscute.ovh";
  #      useSubstitutes = true;
  #      dbi = "dbi:Pg:dbname=hydra;user=hydra;host=192.168.7.5;";
  #    };
  #    nix.buildMachines = [
  #      {
  #        system = "x86_64-linux";
  #        supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark" ];
  #        maxJobs = 8;
  #        hostName = "localhost";
  #      }
  #    ];
  #    networking.firewall.allowedTCPPorts = [ 3000 ];
  #    networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.8"; prefixLength = 24; } ];
  #    networking.defaultGateway = "192.168.7.1";
  #    networking.nameservers = [ "1.1.1.1" ];
  #  };
  #};

  containers.stagit = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    bindMounts = {
      "/git" = { hostPath = "/home/michcioperz/git"; isReadOnly = true; };
      "/stagit" = { hostPath = "/home/michcioperz/stagit"; isReadOnly = false; };
    };
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.9"; prefixLength = 24; } ];
      systemd.services = lib.foldl' (x: y: x // y) {} (map (repoName: {
        "rustagit-${repoName}" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "180";
            ExecStart = ''${pkgs.rustagit}/bin/rustagit /git/${repoName} /stagit/${repoName}'';
          };
        };
      }) ["ace-atourist" "ggd" "nootnootutils" "apocaholics-anonymous" "hugoblog" "raiwu" "blobomnom" "i3spin" "rustagit" "blocks-hanging-out" "icinga-start-dash" "subaru" "defeederated" "lawn" "uhonker" "falsehoods" "lipszyc" "zorza" "f-harvester" "melty" "flux-circulator" "myne" "umiarkowanie-nowy-swiat" "scoobideria" "wordpirate" "nixie"]);
    };
  };

  #containers.sccache = {
  #  privateNetwork = true;
  #  hostBridge = "br0";
  #  autoStart = false;
  #  forwardPorts = [
  #    { containerPort = 10600; hostPort = 10600; protocol = "tcp"; }
  #    { containerPort = 10501; hostPort = 10501; protocol = "tcp"; }
  #  ];
  #  config = { config, lib, pkgs, ... }: {
  #    environment.etc."sccache-scheduler.toml" = {
  #      text = ''
  #        public_addr = "192.168.7.10:10600"
  #        [client_auth]
  #        type = "token"
  #        token = "${secrets.sccache.schedulerToken}"
  #        [server_auth]
  #        type = "jwt_hs256"
  #        secret_key = "${secrets.sccache.schedulerSecretKey}"
  #      '';
  #    };
  #    environment.etc."sccache-server.toml" = {
  #      text = ''
  #        cache_dir = "/tmp/toolchains"
  #        public_addr = "192.168.7.10:10501"
  #        scheduler_url = "http://192.168.7.10:10600"
  #        [builder]
  #        type = "overlay"
  #        build_dir = "/tmp/build"
  #        bwrap_path = "${pkgs.bubblewrap}/bin/bwrap"
  #        [scheduler_auth]
  #        type = "jwt_token"
  #        token = "${secrets.sccache.serverToken}"
  #      '';
  #    };
  #    systemd.services.sccache-scheduler = {
  #      wants = [ "network.target" ];
  #      wantedBy = [ "multi-user.target" ];
  #      serviceConfig = {
  #        Restart = "always";
  #        PrivateTmp = true;
  #        WorkingDirectory = "/tmp";
  #        Environment = "SCCACHE_NO_DAEMON=1";
  #        ExecStart = ''${pkgs.sccache-dist}/bin/sccache-dist scheduler --config /etc/sccache-scheduler.toml'';
  #      };
  #    };
  #    systemd.services.sccache-server = {
  #      wants = [ "network.target" "sccache-scheduler.service" ];
  #      wantedBy = [ "multi-user.target" ];
  #      serviceConfig = {
  #        Restart = "always";
  #        PrivateTmp = true;
  #        WorkingDirectory = "/tmp";
  #        Environment = "SCCACHE_NO_DAEMON=1";
  #        ExecStart = ''${pkgs.sccache-dist}/bin/sccache-dist server --config /etc/sccache-server.toml'';
  #      };
  #    };
  #    networking.firewall.allowedTCPPorts = [ 10600 10501 ];
  #    networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.10"; prefixLength = 24; } ];
  #    networking.defaultGateway = "192.168.7.1";
  #    networking.nameservers = [ "1.1.1.1" ];
  #  };
  #};

  containers.mqtt = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = false;
    forwardPorts = [
      { containerPort = 1883; hostPort = 1883; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      services.mosquitto = {
        enable = true;
        checkPasswords = true;
        host = "0.0.0.0";
        users = {
          public = {
            password = "public";
            acl = [ "topic read radiopush/#" ];
          };
          radiopush = {
            password = secrets.mqtt.radiopushPassword;
            acl = [ "topic write radiopush/#" ];
          };
        };
        extraConf = ''
          listener 8080 0.0.0.0
          protocol websockets
        '';
      };
      #services.rabbitmq = {
      #  enable = true;
      #  cookie = secrets.rabbitmq.cookie;
      #  listenAddress = "0.0.0.0";
      #  plugins = [ "rabbitmq_web_mqtt" "rabbitmq_mqtt" ];
      #};
      #systemd.services.mosquitto.serviceConfig.User = lib.mkForce "root";
      networking.firewall.allowedTCPPorts = [ 1883 ];
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.11"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
    };
  };

  containers.rns = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    forwardPorts = [
      { containerPort = 8000; hostPort = 13370; protocol = "tcp"; }
    ];
    bindMounts = {
      "/tank" = { hostPath = "/tank"; isReadOnly = true; };
    };
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.12"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      networking.firewall.allowedTCPPorts = [ 8000 ];
      services.icecast = {
        enable = true;
        hostname = "www.metro.bieszczady.pl";
        admin.password = secrets.icecast.adminPassword;
        extraConf = ''
        <admin>wysiadam.z.metra@ijestfajnie.pl</admin>
        <location>wwa-desire-01</location>
        <authentication>
          <source-password>${secrets.icecast.sourcePassword}</source-password>
        </authentication>
        '';
      };
      services.liquidsoap.streams.comfy = pkgs.writeScript "comfy.liq" ''
        #!${pkgs.liquidsoap}/bin/liquidsoap
        set("log.stdout", true)
        rain = single("/tank/RainyMood.mp3")
        music = playlist("/tank/slow", reload_mode="rounds", reload=1, mode="randomize")
        radio = add([music, rain])
        input = radio
        password = "${secrets.icecast.sourcePassword}"
        title = "Stacja Techniczno-(Postojowa-w-deszczu)"
        description = "comfy vibes to winter hibernate to"
        genre = "comf"
        output.icecast(%mp3(bitrate=256), mount="/stp.mp3", host="127.0.0.1", port=8000, password=password, public=false, name=title, description=description, genre=genre, input)
        output.icecast(%opus(bitrate=64), mount="/stp.opus", host="127.0.0.1", port=8000, password=password, public=false, name=title, description=description, genre=genre, input)
      '';
      systemd.services."umiarkowanie-nowy-swiat" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "180";
            ExecStart = pkgs.writeScript "nowyswiatstream" ''
              #!${pkgs.runtimeShell}
              ${pkgs.umiarkonowy}/bin/umiarkowanie-nowy-swiat tcp://192.168.7.11:1883 radiopush ${secrets.mqtt.radiopushPassword} https://stream.nowyswiat.online/aac radiopush/nowyswiat >/dev/null''; # | ${pkgs.ffmpeg}/bin/ffmpeg -i - -c:a libopus -vbr on -b:a 32k -content_type audio/ogg -vn -f ogg icecast://source:${secrets.icecast.sourcePassword}@127.0.0.1:8000/rns.opus
          };
      };
      systemd.services."umiarkohonk" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "15";
            ExecStart = pkgs.writeScript "nowyswiathonk" ''
              #!${pkgs.runtimeShell}
              token=$(${pkgs.curl}/bin/curl https://honk.hinata.iscute.ovh/dologin -d "username=nowyswiat&password=${secrets.honk.nowyswiatPassword}&gettoken=1")
              ${pkgs.mosquitto}/bin/mosquitto_sub -h 192.168.7.11 -t radiopush/nowyswiat/StreamTitle -u public -P public | grep --line-buffered -v "Pion i poziom" | while read -r line
              do
                ${pkgs.curl}/bin/curl https://honk.hinata.iscute.ovh/api -d token="$token" -d action=honk --data-urlencode noise="$line"
              done
            '';
          };
      };
    };
  };
  containers.scoobideria = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.13"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      systemd.services.scoobideria = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          Environment = ''TELEGRAM_BOT_TOKEN=${secrets.scoobideria.telegramToken}'';
          ExecStart = ''${pkgs.scoobideria}/bin/scoobideria'';
        };
      };
    };
  };
  #containers.grocy = {
  #  privateNetwork = true;
  #  hostBridge = "br0";
  #  autoStart = true;
  #  config = { config, lib, pkgs, ... }: {
  #    networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.14"; prefixLength = 24; } ];
  #    networking.defaultGateway = "192.168.7.1";
  #    networking.nameservers = ["1.1.1.1"];
  #    networking.firewall.allowedTCPPorts = [ 80 ];
  #    services.grocy = {
  #      enable = true;
  #      hostName = "grocy.hinata.iscute.ovh";
  #      nginx.enableSSL = false;
  #      settings = {
  #        currency = "PLN";
  #        culture =  "pl";
  #        calendar.firstDayOfWeek = 1;
  #      };
  #    };
  #  };
  #};
  containers.bitlbee = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.15"; prefixLength = 24; } ];
      networking.firewall.allowedTCPPorts = [ 6667 ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      services.bitlbee = {
        enable = true;
        hostName = "bitlbee.hinata.iscute.ovh";
        interface = "0.0.0.0";
        authMode = "Registered";
        plugins = [ pkgs.bitlbee-facebook pkgs.bitlbee-mastodon ];
        # libpurple_plugins = [ pkgs.telegram-purple pkgs.purple-slack pkgs.purple-lurch ];
      };
    };
  };
  # containers.bookwyrm = {
  #   privateNetwork = true;
  #   hostBridge = "br0";
  #   autoStart = true;
  #   config = { config, lib, pkgs, ... }: {
  #     networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.17"; prefixLength = 24; } ];
  #     networking.firewall.allowedTCPPorts = [ 8000 8888 ];
  #     networking.defaultGateway = "192.168.7.1";
  #     networking.nameservers = ["1.1.1.1"];
  #     systemd.services.bookwyrmcelery = {
  #       wants = [ "network.target" "redis.service" ];
  #       wantedBy = [ "multi-user.target" ];
  #       serviceConfig = {
  #         Restart = "always";
  #         RestartSec = "15";
  #         ExecStart = ''${pkgs.bookwyrm-env}/bin/celery -A celerywyrm worker -l info'';
  #       };
  #     };
  #     systemd.services.bookwyrmserver = {
  #       wants = [ "network.target" "redis.service" ];
  #       wantedBy = [ "multi-user.target" ];
  #       serviceConfig = {
  #         Restart = "always";
  #         RestartSec = "15";
  #         ExecStart = ''${pkgs.bookwyrm-env}/bin/python ${pkgs.bookwyrm-code}/manage.py runserver 0.0.0.0:8000'';
  #       };
  #     };
  #     systemd.services.bookwyrmflower = {
  #       wants = [ "network.target" "redis.service" ];
  #       wantedBy = [ "multi-user.target" ];
  #       serviceConfig = {
  #         Restart = "always";
  #         RestartSec = "15";
  #         ExecStart = ''${pkgs.bookwyrm-env}/bin/flower --port=8888'';
  #       };
  #     };
  #   };
  # };

  #nixpkgs.config.allowUnfree = true;
  #containers.teamfo = {
  #  privateNetwork = true;
  #  hostBridge = "br0";
  #  autoStart = true;
  #  forwardPorts = [
  #    { containerPort = 27015; hostPort = 27015; protocol = "tcp"; }
  #    { containerPort = 27015; hostPort = 27015; protocol = "udp"; }
  #    { containerPort = 27020; hostPort = 27020; protocol = "udp"; }
  #  ];
  #  config = { config, lib, pkgs, ... }: {
  #    nixpkgs.config.allowUnfree = true;
  #    environment.systemPackages = with pkgs; [
  #      steamPackages.steamcmd
  #    ];
  #    users.users.gameserver = {
  #    };
  #    networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.16"; prefixLength = 24; } ];
  #    networking.firewall.allowedTCPPorts = [ 27015 ];
  #    networking.firewall.allowedUDPPorts = [ 27015 27020 ];
  #  };
  #};

  containers.honk = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.18"; prefixLength = 24; } ];
      networking.firewall.allowedTCPPorts = [ 8000 ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      systemd.services.honk = {
        wants = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "honk";
          Restart = "always";
          RestartSec = "15";
          StateDirectory = ["honk"];
          WorkingDirectory = "/var/lib/honk";
          ExecStart = "${pkgs.honk}/bin/honk -datadir /var/lib/honk -viewdir ${pkgs.honk.src}";
        };
      };
      users.users.honk = {
        home = "/var/lib/honk";
      };
    };
  };
  containers.radyj = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.19"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      networking.firewall.allowedTCPPorts = [ 8000 ];
      systemd.services.radyj = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          ExecStart = ''${pkgs.czy-piec-siedem}/bin/czy-piec-siedem'';
        };
      };
    };
  };
  containers.influxdb = {
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
    forwardPorts = [
      { containerPort = 8086; hostPort = 8086; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: {
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
      networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.7.20"; prefixLength = 24; } ];
      networking.defaultGateway = "192.168.7.1";
      networking.nameservers = ["1.1.1.1"];
      networking.firewall.allowedTCPPorts = [ 8086 ];
      services.influxdb = {
        enable = true;
      };
    };
  };
}

