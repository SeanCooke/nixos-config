# Generating GNOME's monitors.xml and giving it to both the login screen and
# user session.
#
# Arranging laptop and 2 external monitors (one in portrait and one in
# landscape) in a block with the portrait monitor on the bottom-left, the
# laptop on the bottom right, and the landscape monitor on the top-right.

{ lib, pkgs, username, ... }:

let
  # Connectors the external monitors can be assigned to, taken from
  # /sys/class/drm.
  connectors = map (n: "DP-${toString n}") (lib.range 1 8);

  # Laptop display.
  laptop = {
    connector = "eDP-1";
    vendor = "BOE";
    product = "0x0ac1";
    serial = "0x00000000";
    width = 2560;
    height = 1600;
    rate = "120.001";
    scale = "1.6666666666666667";
    rotation = null;
    primary = true;
  };

  # External monitor in portrait.
  portrait = {
    vendor = "VSC";
    product = "VG2239 Series";
    serial = "UBW160203986";
    width = 1920;
    height = 1080;
    rate = "60.000";
    scale = "1";
    rotation = "left";
    primary = false;
  };

  # External monitor in landscape.
  landscape = {
    vendor = "VSC";
    product = "VG2239 Series";
    serial = "UBW160203988";
    width = 1920;
    height = 1080;
    rate = "60.000";
    scale = "1";
    rotation = null;
    primary = false;
  };

  # Function that takes a monitor and puts its top-left corner at position
  # (x, y).
  logicalMonitor = { x, y, connector, monitor }:
    [
      "    <logicalmonitor>"
      "      <x>${toString x}</x>"
      "      <y>${toString y}</y>"
      "      <scale>${monitor.scale}</scale>"
    ]
    ++ lib.optionals (monitor.rotation != null) [
      "      <transform>"
      "        <rotation>${monitor.rotation}</rotation>"
      "      </transform>"
    ]
    ++ lib.optional monitor.primary "      <primary>yes</primary>"
    ++ [
      "      <monitor>"
      "        <monitorspec>"
      "          <connector>${connector}</connector>"
      "          <vendor>${monitor.vendor}</vendor>"
      "          <product>${monitor.product}</product>"
      "          <serial>${monitor.serial}</serial>"
      "        </monitorspec>"
      "        <mode>"
      "          <width>${toString monitor.width}</width>"
      "          <height>${toString monitor.height}</height>"
      "          <rate>${monitor.rate}</rate>"
      "        </mode>"
      "      </monitor>"
      "    </logicalmonitor>"
    ];

  # Generating <logicalmonitor>s from arguments and wrapping them in a
  # <configuration> block.
  configuration = logicalMonitors:
    [
      "  <configuration>"
      "    <layoutmode>logical</layoutmode>"
    ]
    ++ lib.concatMap logicalMonitor logicalMonitors
    ++ [ "  </configuration>" ];

  # laptop will be in every configuration.  Helper function below for putting
  # the top-left corner of laptop at position (x, y).
  dockedLaptop = { x, y }: {
    inherit x y;
    inherit (laptop) connector;
    monitor = laptop;
  };

  # Every ordered pair of distinct connectors, for the portrait and the
  # landscape monitor respectively.
  connectorPairs = lib.concatMap
    (portraitConnector: map
      (landscapeConnector: { inherit portraitConnector landscapeConnector; })
      (lib.filter (c: c != portraitConnector) connectors))
    connectors;

  # GNOME requires every monitor to touch another one with no overlaps, so the
  # external monitors are left aligned with the laptop rather than centred over
  # it. The laptop keeps the same place in every layout that includes it.
  configurations =
    # The laptop on its own.
    [
      (configuration [
        (dockedLaptop { x = 0; y = 0; })
      ])
    ]

    # The portrait monitor to the left of the laptop.
    ++ map
      (c: configuration [
        { x = 0; y = 0; connector = c; monitor = portrait; }
        (dockedLaptop { x = 1080; y = 1080; })
      ])
      connectors

    # The landscape monitor above the laptop.
    ++ map
      (c: configuration [
        { x = 0; y = 0; connector = c; monitor = landscape; }
        (dockedLaptop { x = 0; y = 1080; })
      ])
      connectors

    # The portrait monitor to the left of everything, the landscape monitor
    # above the laptop, and the laptop at the bottom.
    ++ map
      ({ portraitConnector, landscapeConnector }: configuration [
        { x = 0; y = 0; connector = portraitConnector; monitor = portrait; }
        { x = 1080; y = 0; connector = landscapeConnector; monitor = landscape; }
        (dockedLaptop { x = 1080; y = 1080; })
      ])
      connectorPairs;

  monitorsXml = pkgs.writeText "monitors.xml" (lib.concatStringsSep "\n" (
    [ ''<monitors version="2">'' ]
    ++ lib.concatLists configurations
    ++ [ "</monitors>" "" ]
  ));
in

{
  # Giving the login screen the layout by linking the file into GDM's home.
  systemd.tmpfiles.rules = [
    "d /run/gdm/.config 0711 gdm gdm - -"
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsXml}"
  ];

  # Giving the user session the same layout.
  home-manager.users.${username}.home.file.".config/monitors.xml".source =
    monitorsXml;
}
