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

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: rec {
    fractalLock = pkgs.writeScriptBin "fractal-lock" ''
      #!${pkgs.stdenv.shell} -e
      f="$(mktemp)"
      ${pkgs.haskellPackages.FractalArt}/bin/FractalArt --no-bg -w 128 -h 128 -f "$f.bmp"
      ${pkgs.imagemagick}/bin/convert "$f.bmp" \( -clone 0 -flip \) -append \( -clone 0 -flop \) +append "$f.png"
      exec ${pkgs.i3lock}/bin/i3lock -i "$f.png" -f -t
    '';
    firefoxNoGtkTheme = pkgs.symlinkJoin {
      name = "firefox";
      paths = [
        (pkgs.writeScriptBin "firefox" ''
          #!${pkgs.stdenv.shell}
          unset GTK_THEME
          exec ${pkgs.firefox}/bin/firefox "$@"
        '')
        pkgs.firefox
      ];
    };
    rustWithSrc = pkgs.stdenv.mkDerivation {
      name = "rustWithSrc";
      inherit (pkgs.rustc) version src;
      phases = ["unpackPhase" "installPhase"];
      installPhase = ''
        mkdir -p $out
        cp -r src $out/src
        cp -r ${pkgs.rustc}/* $out
      '';
    };
    strawberryProprietary = (pkgs.strawberry.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ (with pkgs.gst_all_1; [ gst-plugins-bad gst-vaapi gst-libav ] ++ [pkgs.libunwind pkgs.elfutils pkgs.orc]);
    })).override { withVlc = false; };
    i3spin = pkgs.rustPlatform.buildRustPackage rec {
      pname = "i3spin";
      version = "0.2.0+1";
      src = pkgs.fetchgit {
        url = "https://git.hinata.iscute.ovh/i3spin/";
        rev = "refs/heads/main";
        sha256 = "14y2pxzaywv44wc057m5zi711lh4y0j7h1npq7fdm1z0v3lpaznc";
      };
      cargoSha256 = "0fnfaalb4vmm5yadfxfbwzadsy5fgqdzrb13wm4dsf830xf1afnv";
      meta = with pkgs.lib; {
        description = "replicates classical DE alt+tab behaviour on i3 window manager";
        homepage = "https://git.hinata.iscute.ovh/i3spin/";
        license = licenses.bsd3;
      };
    };
    ncspot = pkgs.ncspot.override {
      withALSA = false;
      withPulseAudio = true;
      withMPRIS = true;
    };
    coc-nvim = pkgs.vimUtils.buildVimPlugin {
      pname = "coc-nvim";
      version = "0.0.80";
      src = pkgs.fetchFromGitHub {
        owner = "neoclide";
        repo = "coc.nvim";
        rev = "ce448a6945d90609bc5c063577e12b859de0834b";
        sha256 = "1c2spdx4jvv7j52f37lxk64m3rx7003whjnra3y1c7m2d7ljs6rb";
      };
      meta.homepage = "https://github.com/neoclide/coc.nvim/";
    };
    overpass-nerdfont = pkgs.nerdfonts.override { fonts = ["Overpass"]; };
    vim-selenized = pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-selenized";
      version = "2020-05-06";
      src = pkgs.fetchFromGitHub {
        owner = "jan-warchol";
        repo = "selenized";
        rev = "e93e0d9fb47c7485f18fa16f9bdb70c2ee7fb5db";
        sha256 = "07mnfkhjs76z7zxdq08rpsaysb517h8sm51a2iv87mgxjk30pqxg";
      } + "/editors/vim";
      meta.homepage = "https://github.com/jan-warchol-selenized";
    };
    neovim-m314 = pkgs.neovim.override {
      configure = {
        customRC = ''
          set encoding=utf-8
          set background=dark
          set nocompatible
          set updatetime=300
          set cmdheight=2
          set shortmess+=c
          set signcolumn=yes
          set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
          autocmd FileType go,make setlocal noexpandtab
          autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4 colorcolumn=88
          set colorcolumn=80
          set modelines=1
          set number
          set cursorline
          set wildmenu
          set lazyredraw
          set showmatch
          set incsearch
          set hlsearch
          set laststatus=2
          colorscheme selenized
          set termguicolors
          set exrc
          let g:airline_powerline_fonts = 1
          inoremap <silent><expr> <TAB>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<TAB>" :
                \ coc#refresh()
          inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
          
          function! s:check_back_space() abort
            let col = col('.') - 1
            return !col || getline('.')[col - 1]  =~# '\s'
          endfunction
          
          " Use <c-space> to trigger completion.
          if has('nvim')
            inoremap <silent><expr> <c-space> coc#refresh()
          else
            inoremap <silent><expr> <c-@> coc#refresh()
          endif
          " Make <CR> auto-select the first completion item and notify coc.nvim to
          " format on enter, <cr> could be remapped by other vim plugin
          inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                                        \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
          
          " Use `[g` and `]g` to navigate diagnostics
          " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
          nmap <silent> [g <Plug>(coc-diagnostic-prev)
          nmap <silent> ]g <Plug>(coc-diagnostic-next)
          
          " GoTo code navigation.
          nmap <silent> gd <Plug>(coc-definition)
          nmap <silent> gy <Plug>(coc-type-definition)
          nmap <silent> gi <Plug>(coc-implementation)
          nmap <silent> gr <Plug>(coc-references)
          " Use K to show documentation in preview window.
          nnoremap <silent> K :call <SID>show_documentation()<CR>
          
          function! s:show_documentation()
            if (index(['vim','help'], &filetype) >= 0)
              execute 'h '.expand('<cword>')
            elseif (coc#rpc#ready())
              call CocActionAsync('doHover')
            else
              execute '!' . &keywordprg . " " . expand('<cword>')
            endif
          endfunction
          
          " Highlight the symbol and its references when holding the cursor.
          autocmd CursorHold * silent call CocActionAsync('highlight')
          
          " Symbol renaming.
          nmap <leader>rn <Plug>(coc-rename)
          
          " Formatting selected code.
          xmap <leader>f  <Plug>(coc-format-selected)
          nmap <leader>f  <Plug>(coc-format-selected)
          
          augroup mygroup
            autocmd!
            " Setup formatexpr specified filetype(s).
            autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
            " Update signature help on jump placeholder.
            autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
          augroup end
          
          " Applying codeAction to the selected region.
          " Example: `<leader>aap` for current paragraph
          xmap <leader>a  <Plug>(coc-codeaction-selected)
          nmap <leader>a  <Plug>(coc-codeaction-selected)
          
          " Remap keys for applying codeAction to the current buffer.
          nmap <leader>ac  <Plug>(coc-codeaction)
          " Apply AutoFix to problem on the current line.
          nmap <leader>qf  <Plug>(coc-fix-current)
          
          " Map function and class text objects
          " NOTE: Requires 'textDocument.documentSymbol' support from the language server.
          xmap if <Plug>(coc-funcobj-i)
          omap if <Plug>(coc-funcobj-i)
          xmap af <Plug>(coc-funcobj-a)
          omap af <Plug>(coc-funcobj-a)
          xmap ic <Plug>(coc-classobj-i)
          omap ic <Plug>(coc-classobj-i)
          xmap ac <Plug>(coc-classobj-a)
          omap ac <Plug>(coc-classobj-a)
          
          " Remap <C-f> and <C-b> for scroll float windows/popups.
          if has('nvim-0.4.0') || has('patch-8.2.0750')
            nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
            nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
            inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
            inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
            vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
            vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
          endif
          
          " NeoVim-only mapping for visual mode scroll
          " Useful on signatureHelp after jump placeholder of snippet expansion
          if has('nvim')
            vnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#nvim_scroll(1, 1) : "\<C-f>"
            vnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#nvim_scroll(0, 1) : "\<C-b>"
          endif
          
          " Use CTRL-S for selections ranges.
          " Requires 'textDocument/selectionRange' support of language server.
          nmap <silent> <C-s> <Plug>(coc-range-select)
          xmap <silent> <C-s> <Plug>(coc-range-select)
          
          " Add `:Format` command to format current buffer.
          command! -nargs=0 Format :call CocAction('format')
          
          " Add `:Fold` command to fold current buffer.
          command! -nargs=? Fold :call     CocAction('fold', <f-args>)
          
          " Add `:OR` command for organize imports of the current buffer.
          command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
          
          " Mappings for CoCList
          " Show all diagnostics.
          nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
          " Manage extensions.
          nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
          " Show commands.
          nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
          " Find symbol of current document.
          nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
          " Search workspace symbols.
          nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
          " Do default action for next item.
          nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
          " Do default action for previous item.
          nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
          " Resume latest coc list.
          nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
          
          highlight CocFloating ctermbg=0 guibg=bg
          highlight Pmenu ctermbg=0 guibg=bg
          highlight CocErrorSign guifg=#fa5750

        '';
        plug.plugins = with pkgs.vimPlugins; [
          vim-airline
          vim-airline-themes
          vim-nix
          zig-vim
          coc-nvim
          vim-selenized
        ];
      };
    };
  };

}
