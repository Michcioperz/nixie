let
  secrets = (import /etc/nixos/secrets.nix);
  commons = {
    activeContainers = [ "nginx" "prometheus" "grafana" "postgres" "miniflux" "scoobideria" "influxdb" "telegraf" "cmemu" "owncast" ];
    ips = {
      gateway     = "192.168.7.1";
      nginx       = "192.168.7.2";
      prometheus  = "192.168.7.3";
      grafana     = "192.168.7.4";
      postgres    = "192.168.7.5";
      miniflux    = "192.168.7.6";
      scoobideria = "192.168.7.13";
      #honk        = "192.168.7.18";
      influxdb    = "192.168.7.20";
      #meili       = "192.168.7.21";
      #metro       = "192.168.7.24";
      #solarhonk   = "192.168.7.25";
      telegraf    = "192.168.7.28";
      cmemu       = "192.168.7.29";
      owncast     = "192.168.7.30";
    };
    domains = {
      grafana = "grafana.koguma.iscute.ovh";
      #honk = "honk.hinata.iscute.ovh";
      miniflux = "miniflux.koguma.iscute.ovh";
      owncast = "owncast.koguma.iscute.ovh";
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
  nixpkgs.overlays = [ (import ./unstable-overlay.nix) ];
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

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.firewall.logRefusedConnections = false;
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?


  containers.cmemu2 = baseContainer // {
    config = { config, pkgs, ... }: baseContainerConfig { name = "cmemu"; dns = true; } {
      users.users.cmemu = {
        createHome = true;
        home = "/home/cmemu";
      };
      systemd.services."cmemu-nightly@" = let
        sh = pkgs.buildEnv { name="cmemu-build-env"; paths = [ pkgs.rustup pkgs.git pkgs.gcc pkgs.binutils ]; };
        start = pkgs.writeScriptBin "cmemu-build" ''
          #!${pkgs.stdenv.shell} -e
          export PATH="${sh}/bin:$PATH"
          ref="$1"
          upstream="$HOME/playground"
          foo="$(mktemp -d --tmpdir=$HOME)"
          ${pkgs.git}/bin/git clone "$upstream" "$foo"
          ln -sf "$foo" "$HOME/build-root"
          cd "$HOME/build-root"
          ${pkgs.git}/bin/git checkout "$ref"
          cd aj370953/cmemu-framework
          ln -s "$HOME/target" target
          ${pkgs.stdenv.shell} -e ./poors-man-ci.sh
        '';
      in {
        conflicts = [ "cmemu-nightly@.service" ];
        preStart = ''
          upstream="git@github.com:mimuw-distributed-systems-group/playground"
          repo="$HOME/playground"
          mkdir -p "$HOME/.ssh"
          ${pkgs.openssh}/bin/ssh-keyscan github.com > "$HOME/.ssh/known_hosts"
          echo "${secrets.cmemu.sshKey}" > "$HOME/.ssh/id_ed25519"
          chmod 0600 "$HOME/.ssh/id_ed25519"
          [ -d "$repo" ] || ${pkgs.git}/bin/git clone "$upstream" "$repo"
          cd "$repo"
          ${pkgs.git}/bin/git pull --ff-only
          ${pkgs.rustup}/bin/rustup toolchain add stable --profile minimal --component rustfmt
          ${pkgs.rustup}/bin/rustup toolchain add nightly --profile minimal --component clippy
          ${pkgs.rustup}/bin/rustup update
          mkdir -p "$HOME/target"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "cmemu";
          Group = "nogroup";
          CPUWeight = "1";
          IOWeight = "1";
          ExecStart = "${start}/bin/cmemu-build %i";
        };
      };
    };
  };

  containers.grafana = baseContainer // {
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

  containers.influxdb = baseContainer // {
    forwardPorts = [
      { containerPort = 8086; hostPort = 8086; protocol = "tcp"; }
    ];
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "influxdb"; dns = true; tcp = [8086]; } {
      services.influxdb = {
        enable = true;
        package = pkgs.unstable.influxdb2;
        extraConfig = let cfg = config.services.influxdb; in {
          bolt-path = ''${cfg.dataDir}/influxd.bolt'';
          engine-path = ''${cfg.dataDir}/engine'';
          http-bind-address = '':8086'';
        };
      };
      systemd.services.influxdb = {
        serviceConfig = {
          Environment = ''INFLUXD_CONFIG_PATH=${(pkgs.writeText "config.json" (builtins.toJSON config.services.influxdb.extraConfig))}'';
          ExecStart = lib.mkForce ''${config.services.influxdb.package}/bin/influxd'';
        };
      };
    };
  };

  containers.miniflux = baseContainer // {
    config = { config, pkgs, lib, ... }: baseContainerConfig { name = "miniflux"; tcp = [8080]; dns = true; } {
      services.miniflux = {
        enable = true;
        config = lib.mkForce {
          DATABASE_URL = "user=miniflux dbname=miniflux sslmode=disable host=${commons.ips.postgres}";
          PORT = "8080";
          BASE_URL = "https://${commons.domains.miniflux}/";
          METRICS_COLLECTOR = "1";
          METRICS_ALLOWED_NETWORKS = "${commons.ips.prometheus}/32,${commons.ips.telegraf}/32";
          RUN_MIGRATIONS = "1";
        };
      };
      services.postgresql.enable = lib.mkForce false;
      services.postgresql.package = pkgs.postgresql_11;
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

  containers.nginx = baseContainer // {
    forwardPorts = [
      { containerPort = 80; hostPort = 80; protocol = "tcp"; }
      { containerPort = 443; hostPort = 443; protocol = "tcp"; }
      { containerPort = 6697; hostPort = 6697; protocol = "tcp"; }
    ];
    config = { config, pkgs, ... }: baseContainerConfig { name = "nginx"; dns = true; tcp = [80 443]; } {
      security.acme.email = "acme.koguma@iscute.ovh";
      security.acme.acceptTerms = true;
      services.nginx = {
        enable = true;
        package = pkgs.nginxMainline;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        statusPage = true;
        virtualHosts = {
          "meekchopp.es" = {
            enableACME = true;
            forceSSL = true;
            default = true;
            locations."/" = {
              root = let
                disambiguationSite = pkgs.writeTextDir "index.html" ''
                  <html>
                    <head>
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
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              root = "${pkgs.meekchoppes}/share/meekchoppes/en";
            };
          };
          "ijestfajnie.pl" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              root = "${pkgs.meekchoppes}/share/meekchoppes/pl";
            };
          };
          "${commons.domains.grafana}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${commons.ips.grafana}:3000";
            };
          };
          "${commons.domains.miniflux}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${commons.ips.miniflux}:8080";
            };
          };
        };
      };
      services.prometheus.exporters.nginx = {
        enable = true;
        openFirewall = true;
      };
    };
  };

  containers.owncast = baseContainer // {
    config = { config, pkgs, lib, ... }: baseContainerConfig { name = "owncast"; tcp = [ 1935 8080 ]; } {
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

  containers.postgres = baseContainer // {
    config = { config, pkgs, lib, ... }: baseContainerConfig { name = "postgres"; tcp = [5432]; } {
      services.postgresql = let pgservices = [ "miniflux" ]; in {
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

  containers.prometheus = baseContainer // {
    config = { config, ... }: baseContainerConfig { name = "prometheus"; tcp = [9090]; } {
      services.prometheus = {
        enable = true;
        port = 9090;
        #remoteWrite = [
        #  {
        #    #TODO: url = "http://${commons.ips.influxdb}:8086/api/v1/prom/write?db=prometheus";
        #  }
        #];
        scrapeConfigs = [
          #TODO: raspi
          #TODO: nginx
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

  containers.scoobideria = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "scoobideria"; dns = true; } {
      systemd.services.scoobideria = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "15";
          Environment = ''TELEGRAM_BOT_TOKEN=${secrets.scoobideria.telegramToken}'';
          ExecStart = ''${pkgs.unstable.scoobideria}/bin/scoobideria'';
        };
      };
    };
  };

  containers.telegraf = baseContainer // {
    config = { config, lib, pkgs, ... }: baseContainerConfig { name = "telegraf"; } {
      services.telegraf = {
        enable = true;
        package = pkgs.unstable.telegraf;
        extraConfig = {
          agent = {
            interval = "60s";
            round_interval = true;
          };
          inputs = {
            prometheus = {
              metric_version = 2;
              urls = [
                "http://${commons.ips.nginx}:9113/metrics"
                "http://${commons.ips.miniflux}:8080/metrics"

                "http://192.168.2.1:9100/metrics" # openwrt
                "http://192.168.2.13:8876/metrics" # fronius
                "http://192.168.2.13:8763/metrics" # ecosol
              ] ++ (map (ip: "http://${commons.ips.${ip}}:9100/metrics") (["gateway"] ++ commons.activeContainers));
            };
            #mqtt_consumer = {
            #  servers = ["tcp://192.168.2.1:1883"];
            #  topics = ["sensor/#"];
            #};
          };
          outputs = {
            influxdb_v2 = {
              urls = [ "http://${commons.ips.influxdb}:8086" ];
              token = secrets.influxdb.telegrafToken;
              bucket = "telegraf";
              organization = "Misunderstanding Overenthusiastic Engineering";
            };
          };
        };
      };
    };
  };
}

