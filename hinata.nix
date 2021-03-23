let
  secrets = (import /etc/nixos/secrets.nix);
  commons = {
    activeContainers = [ "nginx" "prometheus" "grafana" "postgres" "miniflux" "ipmiprom" "stagit" "mqtt" "rns" "scoobideria" "bitlbee" "honk" "radyj" "influxdb" "meili" "powerdns" ];
    ips = {
      gateway     = "192.168.7.1";
      nginx       = "192.168.7.2";
      prometheus  = "192.168.7.3";
      grafana     = "192.168.7.4";
      postgres    = "192.168.7.5";
      miniflux    = "192.168.7.6";
      ipmiprom    = "192.168.7.7";
      hydra       = "192.168.7.8";
      stagit      = "192.168.7.9";
      sccache     = "192.168.7.10";
      mqtt        = "192.168.7.11";
      rns         = "192.168.7.12";
      scoobideria = "192.168.7.13";
      grocy       = "192.168.7.14";
      bitlbee     = "192.168.7.15";
      teamfo      = "192.168.7.16";
      bookwyrm    = "192.168.7.17";
      honk        = "192.168.7.18";
      radyj       = "192.168.7.19";
      influxdb    = "192.168.7.20";
      meili       = "192.168.7.21";
      powerdns    = "192.168.7.22";
    };
    domains = {
      honk = "honk.hinata.iscute.ovh";
    };
  };
  baseContainer = {
    timeoutStartSec = "2min";
    privateNetwork = true;
    hostBridge = "br0";
    autoStart = true;
  };
  baseContainerConfig = { name, dns ? false, tcp ? [], udp ? [], ... }: config:
    assert !(config?networking);
    config // {
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
{ config, pkgs, ... }:
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
  networking.interfaces.br0 = { ipv4.addresses = [ { address = "${commons.ips.gateway}"; prefixLength = 24; } ]; };

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
    wget neovim htop git tmux nncp
  ];

  services.borgbackup.jobs = {
    rootBackup = {
      compression = "zstd";
      encryption.mode = "keyfile-blake2";
      encryption.passphrase = "";
      exclude = [ "/nix" "/tank" "/sys" "/proc" "/dev" "/lost+found" "/run" "/tmp" ];
      paths = "/";
      repo = "ysvg35ac@ysvg35ac.repo.borgbase.com:repo";
    };
  };

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

  containers.nginx2 = baseContainer // {
    forwardPorts = [
      { containerPort = 80; hostPort = 80; protocol = "tcp"; }
      { containerPort = 443; hostPort = 443; protocol = "tcp"; }
      { containerPort = 6697; hostPort = 6697; protocol = "tcp"; }
    ];
    bindMounts = {
      "/git" = { hostPath = "/home/michcioperz/git"; isReadOnly = true; };
      "/radyj-public" = { hostPath = "/home/michcioperz/radyj-public"; isReadOnly = true; };
      "/stagit" = { hostPath = "/home/michcioperz/stagit"; isReadOnly = true; };
      "/tank" = { hostPath = "/tank"; isReadOnly = true; };
      #"/nsu" = { hostPath = "/home/michcioperz/nsu"; isReadOnly = true; };
    };
    config = { config, pkgs, ... }: baseContainerConfig { name = "nginx"; dns = true; tcp = [80 443 6697]; } {
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
            serverAliases = [ "metro.bieszczady.pl" ];
            enableACME = true;
            addSSL = true;
            basicAuth = { "comfy" = secrets.icecast.comfyPassword; };
            locations."/" = {
              extraConfig = ''proxy_pass_header Authorization;'';
              proxyPass = "http://${commons.ips.rns}:8000";
            };
          };
          "nixpkgs.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."/indexes" = {
              proxyPass = "http://${commons.ips.meili}:7700";
            };
            locations."/" = {
              root = "/tank/nixpkgs-ui";
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
              proxyPass = "http://${commons.ips.grafana}:3000";
            };
          };
          "radyj.hinata.iscute.ovh" = {
            enableACME = true;
            addSSL = true;
            locations."/" = {
              root = "/radyj-public";
            };
            locations."/api" = {
              proxyPass = "http://${commons.ips.radyj}:8000";
              extraConfig = ''add_header Cache-Control "public, immutable, max-age=3600"; proxy_cache radyj; proxy_cache_lock on; proxy_cache_revalidate off; proxy_cache_valid 1h;'';
            };
          };
          "${commons.domains.honk}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${commons.ips.honk}:8000";
            };
          };
          "miniflux.hinata.iscute.ovh" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${commons.ips.miniflux}:8080";
            };
          };
          #"mqtt.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  http2 = false;
          #  locations."/" = {
          #    proxyPass = "http://${commons.ips.mqtt}:15675";
          #    proxyWebsockets = true;
          #  };
          #};
          #"hydra.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  locations."/" = {
          #    proxyPass = "http://${commons.ips.hydra}:3000";
          #  };
          #};
          #"grocy.hinata.iscute.ovh" = {
          #  enableACME = true;
          #  forceSSL = true;
          #  locations."/" = {
          #    proxyPass = "http://${commons.ips.grocy}:80";
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
              server ${commons.ips.bitlbee}:6667 max_fails=3 fail_timeout=10s;
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
    };
  };

  containers.prometheus = baseContainer // {
    config = { config, ... }: baseContainerConfig { name = "prometheus"; tcp = [9090]; } {
      services.prometheus = {
        enable = true;
        port = 9090;
        remoteWrite = [
          {
            url = "http://${commons.ips.influxdb}:8086/api/v1/prom/write?db=prometheus";
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
            static_configs = [ { targets = map (ip: commons.ips.${ip} + ":9100") ([ "gateway" ] ++ commons.activeContainers); } ];
          }
          {
            job_name = "postgres";
            static_configs = [ { targets = [ "${commons.ips.postgres}:9187" ]; } ];
          }
          {
            job_name = "miniflux";
            static_configs = [ { targets = [ "${commons.ips.miniflux}:8080" ]; } ];
          }
          {
            job_name = "icecast";
            static_configs = [ { targets = [ "${commons.ips.rns}:9146" ]; } ];
          }
          {
            job_name = "powerdns";
            static_configs = [ { targets = [ "${commons.ips.powerdns}:8081" ]; } ];
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
                replacement = "${commons.ips.ipmiprom}:9290";
                action = "replace";
              }
            ];
          }
        ];
      };
    };
  };

  containers.grafana = baseContainer // {
    config = { config, ... }: baseContainerConfig { name = "grafana"; dns = true; tcp = [3000]; } {
      services.grafana = {
        enable = true;
        addr = "0.0.0.0";
        domain = "grafana.hinata.iscute.ovh";
        rootUrl = "https://grafana.hinata.iscute.ovh/";
        security.adminUser = "michcioperz";
      };
    };
  };

  containers.postgres = baseContainer // {
    config = { config, pkgs, lib, ... }: baseContainerConfig { name = "postgres"; tcp = [5432]; } {
      services.postgresql = let pgservices = [ "miniflux" "hydra" "powerdns" ]; in {
        enable = true;
        package = pkgs.postgresql_11;
        enableTCPIP = true;
        ensureDatabases = pgservices;
        ensureUsers = map (name: { name = name; ensurePermissions = { "DATABASE ${name}" = "ALL PRIVILEGES"; }; }) pgservices;
        authentication = lib.strings.concatMapStringsSep "\n" (name: "host ${name} ${name} ${commons.ips."${name}"}/32 trust") pgservices;
      };
      services.prometheus.exporters.postgres = {
        enable = true;
        openFirewall = true;
        runAsLocalSuperUser = true;
      };
    };
  };

  containers.miniflux = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "miniflux"; dns = true; tcp = [8080]; } {
      services.miniflux = {
        enable = true;
        config = lib.mkForce {
          DATABASE_URL = "user=miniflux dbname=miniflux sslmode=disable host=${commons.ips.postgres}";
          PORT = "8080";
          BASE_URL = "https://miniflux.hinata.iscute.ovh/";
          METRICS_COLLECTOR = "1";
          METRICS_ALLOWED_NETWORKS = "${commons.ips.prometheus}/32";
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
    };
  };

  containers.ipmiprom = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "ipmiprom"; tcp = [9290]; } {
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
    };
  };

  #containers.hydra = baseContainer // {
  #  config = { config, lib, pkgs, ... }: baseContainerConfig { name = "hydra"; dns = true; tcp = [3000]; } {
  #    services.hydra = {
  #      enable = true;
  #      hydraURL = "https://hydra.hinata.iscute.ovh";
  #      notificationSender = "hydra@hinata.iscute.ovh";
  #      useSubstitutes = true;
  #      dbi = "dbi:Pg:dbname=hydra;user=hydra;host=${commons.ips.postgres};";
  #    };
  #    nix.buildMachines = [
  #      {
  #        system = "x86_64-linux";
  #        supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark" ];
  #        maxJobs = 8;
  #        hostName = "localhost";
  #      }
  #    ];
  #  };
  #};

  containers.stagit = baseContainer // {
    bindMounts = {
      "/git" = { hostPath = "/home/michcioperz/git"; isReadOnly = true; };
      "/stagit" = { hostPath = "/home/michcioperz/stagit"; isReadOnly = false; };
    };
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "stagit"; } {
      systemd.services = lib.foldl' (x: y: x // y) {} (map (repoName: {
        "rustagit-${repoName}" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "180";
            ExecStart = ''${pkgs.rustagit}/bin/rustagit /git/${repoName} /stagit/${repoName}'';
          };
        };
      }) ["ace-atourist" "ggd" "nootnootutils" "apocaholics-anonymous" "hugoblog" "raiwu" "blobomnom" "i3spin" "rustagit" "blocks-hanging-out" "icinga-start-dash" "subaru" "defeederated" "lawn" "uhonker" "falsehoods" "lipszyc" "zorza" "f-harvester" "melty" "flux-circulator" "myne" "umiarkowanie-nowy-swiat" "scoobideria" "wordpirate" "nixie" "ecosol_exporter"]);
    };
  };

  #containers.sccache = baseContainer // {
  #  forwardPorts = [
  #    { containerPort = 10600; hostPort = 10600; protocol = "tcp"; }
  #    { containerPort = 10501; hostPort = 10501; protocol = "tcp"; }
  #  ];
  #  config = { config, lib, pkgs, ... }: baseContainerConfig { name = "sccache"; dns = true; tcp = [10600 10501]; } {
  #    environment.etc."sccache-scheduler.toml" = {
  #      text = ''
  #        public_addr = "${commons.ips.sccache}:10600"
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
  #        public_addr = "${commons.ips.sccache}:10501"
  #        scheduler_url = "http://${commons.ips.sccache}:10600"
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
  #  };
  #};

  containers.mqtt = baseContainer // {
    forwardPorts = [
      { containerPort = 1883; hostPort = 1883; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "mqtt"; tcp = [1883]; } {
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
    };
  };

  containers.rns = baseContainer // {
    forwardPorts = [
      { containerPort = 8000; hostPort = 13370; protocol = "tcp"; }
    ];
    bindMounts = {
      "/tank" = { hostPath = "/tank"; isReadOnly = true; };
    };
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "rns"; dns = true; tcp = [8000 9146]; } {
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
      systemd.services.icecast-exporter = {
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          PrivateTmp = true;
          WorkingDirectory = "/tmp";
          ExecStart = ''
            ${pkgs.icecast-exporter}/bin/icecast_exporter \
              --web.listen-address :9146 --icecast.time-format "Mon, 02 Jan 2006 15:04:05 -0700"
          '';
        };
      };
      services.liquidsoap.streams.comfy = pkgs.writeScript "comfy.liq" ''
        #!${pkgs.liquidsoap}/bin/liquidsoap
        set("log.stdout", true)
        rain = single("/tank/RainyMood.mp3")
        music = playlist("/tank/normslow", reload_mode="rounds", reload=1, mode="randomize")
        radio = add([music, rain])
        input = radio
        password = "${secrets.icecast.sourcePassword}"
        title = "Stacja Techniczno-(Postojowa-w-deszczu)"
        description = "comfy vibes to winter hibernate to"
        genre = "comf"
        output.icecast(%mp3(bitrate=128), mount="/stp.mp3", host="127.0.0.1", port=8000, password=password, public=false, name=title, description=description, genre=genre, input)
        output.icecast(%opus(bitrate=32), mount="/stp.opus", host="127.0.0.1", port=8000, password=password, public=false, name=title, description=description, genre=genre, input)
      '';
      systemd.services."umiarkowanie-nowy-swiat" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "180";
            ExecStart = pkgs.writeScript "nowyswiatstream" ''
              #!${pkgs.runtimeShell}
              ${pkgs.umiarkonowy}/bin/umiarkowanie-nowy-swiat tcp://${commons.ips.mqtt}:1883 radiopush ${secrets.mqtt.radiopushPassword} https://stream.nowyswiat.online/aac radiopush/nowyswiat >/dev/null''; # | ${pkgs.ffmpeg}/bin/ffmpeg -i - -c:a libopus -vbr on -b:a 32k -content_type audio/ogg -vn -f ogg icecast://source:${secrets.icecast.sourcePassword}@127.0.0.1:8000/rns.opus
          };
      };
      systemd.services."umiarkohonk" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "always";
            RestartSec = "15";
            ExecStart = pkgs.writeScript "nowyswiathonk" ''
              #!${pkgs.runtimeShell}
              token=$(${pkgs.curl}/bin/curl https://${commons.domains.honk}/dologin -d "username=nowyswiat&password=${secrets.honk.nowyswiatPassword}&gettoken=1")
              ${pkgs.mosquitto}/bin/mosquitto_sub -h ${commons.ips.mqtt} -t radiopush/nowyswiat/StreamTitle -u public -P public | grep --line-buffered -v "Pion i poziom" | while read -r line
              do
                ${pkgs.curl}/bin/curl https://${commons.domains.honk}/api -d token="$token" -d action=honk --data-urlencode noise="$line"
              done
            '';
          };
      };
      services.cron.enable = true;
      services.cron.systemCronJobs = let
        solarhonkPython = pkgs.python3.withPackages (ps: [ps.influxdb ps.pytz ps.requests]);
        solarhonk = pkgs.writeScript "solarhonk" ''
          #!${solarhonkPython}/bin/python3
          import datetime
          from influxdb import InfluxDBClient
          import pytz
          import requests

          warsaw = pytz.timezone("Europe/Warsaw")
          now = warsaw.fromutc(datetime.datetime.utcnow())
          today = now.replace(hour=0, minute=0, second=0, microsecond=0)

          client = InfluxDBClient(host="${commons.ips.influxdb}", database="prometheus")
          best_of_today_query = "SELECT last(value) FROM fronius_site_energy_consumption WHERE time_frame = 'day' AND time >= $t GROUP BY time(1d) fill(null) tz('Europe/Warsaw')"
          best_of_today = next(client.query(best_of_today_query, bind_params={"t": today.isoformat()}).get_points())["last"]
          best_of_today_kwh = best_of_today / 1000

          first_of_best_query = "SELECT first(value) FROM fronius_site_energy_consumption WHERE time_frame = 'day' AND time >= $t AND value = $v tz('Europe/Warsaw')"
          first_of_best_str = next(client.query(first_of_best_query, bind_params={"t": today.isoformat(), "v": best_of_today}).get_points())["time"]
          assert first_of_best_str.endswith("Z")
          first_of_best = pytz.UTC.localize(datetime.datetime.fromisoformat(first_of_best_str[:-1])).astimezone(warsaw)

          token_response = requests.post("https://${commons.domains.honk}/dologin", {"username": "solar", "gettoken": "1", "password": "${secrets.honk.solarPassword}"})
          token_response.raise_for_status()
          token = token_response.text.strip()

          requests.post("https://${commons.domains.honk}/api", {"token": token, "action": "honk", "noise": f"Today's photovoltaic production was {best_of_today_kwh:.3f} kilowatt-hours, according to the last increase in reading from {first_of_best.time().strftime('%H:%M')} local time"}).raise_for_status()
        '';
      in [ "0 21 * * * ${solarhonk}" ];
    };
  };
  containers.scoobideria = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "scoobideria"; dns = true; } {
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
  #containers.grocy = baseContainer // {
  #  config = { config, lib, pkgs, ... }: baseContainerConfig { name = "grocy"; dns = true; tcp = [80]; } {
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
  containers.bitlbee = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "bitlbee"; dns = true; tcp = [6667]; } {
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
  # containers.bookwyrm = baseContainer // {
  #   config = { config, lib, pkgs, ... }: baseContainerConfig { name = "bookwyrm"; dns = true; tcp = [8000 8888]; } {
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

  containers.honk = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "honk"; dns = true; tcp = [8000]; } {
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
  containers.radyj = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "radyj"; dns = true; tcp = [8000]; } {
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
  containers.influxdb = baseContainer // {
    forwardPorts = [
      { containerPort = 8086; hostPort = 8086; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "influxdb"; dns = true; tcp = [8086]; } {
      services.influxdb = {
        enable = true;
        extraConfig = {
          http.log-enabled = false;
        };
      };
    };
  };
  containers.meili = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "meili"; tcp = [7700]; } {
      systemd.services.meilisearch = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          User = "meilisearch";
          StateDirectory = ["meilisearch"];
          ExecStart = ''${pkgs.meilisearch-bin}/bin/meilisearch --db-path /var/lib/meilisearch --http-addr 0.0.0.0:7700 --master-key ${secrets.meilisearch.masterKey} --env production'';
        };
      };
      users.users.meilisearch = {
        home = "/var/lib/meilisearch";
      };
    };
  };
  containers.powerdns = baseContainer // {
    forwardPorts = [
      { containerPort = 53; hostPort = 53; protocol = "tcp"; }
      { containerPort = 53; hostPort = 53; protocol = "udp"; }
      { containerPort = 8081; hostPort = 8053; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "powerdns"; tcp = [53 8081]; udp = [53]; } {
      services.powerdns.enable = true;
      services.powerdns.extraConfig = ''
        expand-alias=yes
        resolver=1.1.1.1:53
        launch=gpgsql
        gpgsql-host=${commons.ips.postgres}
        gpgsql-user=powerdns
        gpgsql-dbname=powerdns
        webserver=yes
        webserver-address=0.0.0.0
        webserver-allow-from=192.168.0.0/20
        api=yes
        api-key=${secrets.powerdns.api-key}
      '';
    };
  };
}

