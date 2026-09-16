{ config, pkgs, lib, username, ... }:

let
  # Requiring git authentication from command line only.
  unsetSshAskpass = "unset SSH_ASKPASS";

  # Converts JSONC into plain JSON.
  jsoncToJson = pkgs.writers.writePython3Bin "jsonc-to-json" {
    libraries = [ pkgs.python3Packages.json5 ];
  } ''
    import json
    import json5
    import sys

    with open(sys.argv[1]) as settings:
        parsed = json5.load(settings)

    if not isinstance(parsed, dict):
        sys.exit("Input is not a JSON object.")

    json.dump(parsed, sys.stdout)
  '';

  # Merging this repo's settings into the application's settings file.  Merge
  # used rather than replace as the application also writes to this settings
  # file and we don't want to overwrite its settings.
  #
  #   appName         - human readable name used in warnings, e.g. "Claude Code"
  #   appSettingsFile - settings file under apps/, e.g.
  #                     "claude-code/settings.json"
  #   target          - settings file the application reads, may reference $HOME
  #                   - e.g. "$HOME/.claude/settings.json"
  mergeAppSettings = { appName, appSettingsFile, target }:
    let
      relativeSource = "apps/${appSettingsFile}";
      source = ./.. + "/${relativeSource}";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${target}"
      mkdir -p "$(dirname "$settings")"

      # $settings might have comments so we explicitly convert to JSON
      # parsable by jq.
      json="$(mktemp)"
      if ! ${jsoncToJson}/bin/jsonc-to-json "$settings" > "$json" 2>/dev/null; then
        echo '{}' > "$json"
      fi

      # Merge ${relativeSource} into the settings file via a scratch file,
      # giving priority to keys in ${relativeSource}. If the merge succeeds,
      # replace the settings file with the scratch file.
      tmp="$(mktemp "$settings.XXXXXX")"
      if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$json" ${source} > "$tmp"; then
        mv "$tmp" "$settings"
      else
        rm -f "$tmp"
        warnEcho \
          "Unable to import ${appName} settings from ${relativeSource}." \
          "${appName} will continue to use the settings in ${target}."
      fi
      rm -f "$json"
    '';
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited
    # # number of fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make
    # # '~/.screenrc' a symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # Configuring global zoom.
    ".config/monitors.xml".source = ./monitors.xml;
  };

  # Configuring Brave.
  home.activation.braveSettings = mergeAppSettings {
    appName = "Brave";
    appSettingsFile = "brave/settings.json";
    target = "$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences";
  };

  # Configuring Claude Code.
  home.activation.claudeCodeSettings = mergeAppSettings {
    appName = "Claude Code";
    appSettingsFile = "claude-code/settings.json";
    target = "$HOME/.claude/settings.json";
  };

  # Configuring Visual Studio Code.
  home.activation.vscodeSettings = mergeAppSettings {
    appName = "Visual Studio Code";
    appSettingsFile = "visual-studio-code/settings.json";
    target = "$HOME/.config/Code/User/settings.json";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/scooke/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    bashrcExtra = unsetSshAskpass;
  };

  # Installing Oh My Zsh. The default shell is set to zsh in
  # nixos/configuration.nix.
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
    envExtra = unsetSshAskpass;
  };

  dconf.settings = {
    # Configuring the GNOME dock.
    "org/gnome/shell" = {
      favorite-apps = [
        "brave-browser.desktop"
        "org.gnome.Geary.desktop"
        "spotify.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    # Increasing the Console font size by a multiplier.
    "org/gnome/Console" = {
      font-scale = 1.5;
    };

    # Configuring desktop background.
    "org/gnome/desktop/background" = {
      picture-uri-dark = "file://${pkgs.fetchurl {
        url = "https://www.wallpaperinhd.net/wp-content/uploads/2018/11/Star-Wars-Wallpaper-099.jpg";
        hash = "sha256-vq15sLrZbd6uv7PPJsVtcC7iXCMq1AedaVrwYZTc0Jw=";
      }}";
    };

    # Media keyboard shortcuts.
    "org/gnome/settings-daemon/plugins/media-keys" = {
      play = [ "<Control><Super>space" ];
      next = [ "<Control><Super>Right" ];
      previous = [ "<Control><Super>Left" ];
    };
  };

}
