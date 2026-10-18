# Generating GNOME's monitors.xml.
#
# Mutter applies a stored <configuration> only when the set of connected
# monitors exactly matches the set of <monitorspec>s in that configuration, and
# a monitorspec includes the connector (DP-1, DP-3, ...) alongside the vendor,
# product and serial. The kernel hands out connectors in the order monitors
# turn up, so unplugging and re-plugging a monitor can move it from DP-2 to
# DP-3. Mutter then recognises none of the stored configurations and falls back
# to arranging every monitor in a left to right row.
#
# To make the layout stick we emit one <configuration> for every connector the
# external monitors could be assigned to, so the layout is found again no
# matter which port the monitors come back on.

{ lib, pkgs }:

let
  # Connectors the external monitors can be assigned to, taken from
  # /sys/class/drm.
  connectors = map (n: "DP-${toString n}") (lib.range 1 8);

  # The laptop display. 2560x1600 at a scale of 1.6666... is 1536x960 logical
  # pixels.
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

  # The external monitor rotated into portrait, 1080x1920 logical pixels.
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

  # The external monitor left in landscape, 1920x1080 logical pixels.
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

  # Rendering a <logicalmonitor> that puts `monitor` on `connector` with its
  # top left corner at logical coordinates (x, y). Returns a list of lines.
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

  # Rendering a <configuration> from a list of logicalMonitor arguments.
  configuration = logicalMonitors:
    [
      "  <configuration>"
      "    <layoutmode>logical</layoutmode>"
    ]
    ++ lib.concatMap logicalMonitor logicalMonitors
    ++ [ "  </configuration>" ];

  # The laptop in the position it holds whenever an external is attached.
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
        { x = 0; y = 0; connector = laptop.connector; monitor = laptop; }
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
in

pkgs.writeText "monitors.xml" (lib.concatStringsSep "\n" (
  [ ''<monitors version="2">'' ]
  ++ lib.concatLists configurations
  ++ [ "</monitors>" "" ]
))
