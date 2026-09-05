# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, fullName, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Loading the latest Linux kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enabling VPN from GNOME.
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # The kernel virtual console (Ctrl+Alt+F3, and any boot-time output) is drawn
  # by the kernel, not the compositor, so the display scale in monitors.xml
  # cannot reach it. Its default font is a fixed 8x16 bitmap; Terminus 14x28 is
  # the size closest to that scale. Terminus only resolves if its package is
  # listed here too, as kbd does not ship it.
  console = {
    font = "ter-i28b";
    packages = [ pkgs.terminus_font ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # Removing default Web application since we use Brave.
  environment.gnome.excludePackages = with pkgs; [ epiphany ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enabling Bluetooth on boot and after autosuspend.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
  '';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    claude-code
    gh
    git
    keepassxc
    openvpn
    (pkgs.brave.override {
      commandLineArgs = [
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];
    })
    libreoffice
    (python3.withPackages (ps: with ps; [
      jupyter
      numpy
      pandas
      pytest
      scikit-learn
    ]))
    slack
    spotify
    tree
    unzip
    vim
    (pkgs.vscode-with-extensions.override {
      vscodeExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "laserwave";
          publisher = "jaredkent";
          version = "1.3.3";
          sha256 = "0pfp07fvq1if214r9nz64hasnsrn8jrlfb4pkckv5wf0wwm5vgs4";
        }
      ] ++ (with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.debugpy
      ]);
    })
    wget
    zoom-us
  ];

  # Runs Chromium and Electron applications (Brave, VS Code, Slack, Spotify) as
  # native Wayland clients rather than under Xwayland. They then receive the
  # display scale from monitors.xml directly and render at it, which is what
  # lets them be sized by that one setting instead of per-application zoom
  # flags. Without this they are drawn at scale 1 and stretched, so text in
  # them looks soft.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Setting default command line editor to vim.
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Setting default shell to zsh.
  programs.zsh.enable = true;

  # Setting default web browser to Brave.
  xdg.mime.defaultApplications = {
    "text/html"              = "brave-browser.desktop";
    "x-scheme-handler/http"  = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
  };

  # Configuring Brave policies.
  environment.etc."/brave/policies/managed/GroupPolicy.json".source = ./../apps/brave/policies.json;

  # Enabling docker.
  virtualisation.docker = {
    enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # Enable GNOME Dark Mode.
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        # Xwayland clients are drawn at scale 1 and stretched by the compositor,
        # which leaves them blurry under the fractional scale in monitors.xml.
        # This asks them to render at the real scale instead. Only affects apps
        # that are still on X11; the Chromium and Electron ones are moved to
        # native Wayland by NIXOS_OZONE_WL above.
        "org/gnome/mutter" = {
          experimental-features = [ "xwayland-native-scaling" ];
        };
        # Console sizes its text from the monospace font's point size, which
        # the display scale in monitors.xml magnifies along with everything
        # else. That still leaves it smaller than is comfortable to read, so
        # scale its font up on top of the display scale.
        "org/gnome/Console" = {
          font-scale = 1.5;
        };
      };
    }
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
