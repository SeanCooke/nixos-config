# nixos-config
Collection of configuration files that declaratively define applications and settings on my NixOS laptop, managed as a [Nix flake](https://wiki.nixos.org/wiki/Flakes).

## Layout
- `flake.nix` — Entrypoint. Defines the `laptop` system and wires in [Home Manager](https://github.com/nix-community/home-manager) as a NixOS module.
- `flake.lock` — Pinned revisions of `nixpkgs` and `home-manager`.
- `home-manager/home.nix` — Home Manager.
- `images/face.jpg` — Profile picture.  Replace it with your own.
- `nixos/configuration.nix` — System configuration.
- `nixos/hardware-configuration.nix` — Example hardware scan.  Replace it with your own `/etc/nixos/hardware-configuration.nix`.

## Install
`nixos-config` can only be run on machines where NixOS is already installed. You can download the NixOS ISO from the [official NixOS download page](https://nixos.org/download/#nixos-iso).

1. Clone this github repo into your home directory.
```bash
cd ~/
nix-shell -p git
git clone https://github.com/SeanCooke/nixos-config
```

2. Change into the repo and run [`install.sh`](https://github.com/SeanCooke/nixos-config/blob/main/install.sh). It replaces the tracked hardware scan, enables flakes, and builds the system.
```bash
cd ~/nixos-config
./install.sh
```

Once this configuration is active, flakes are enabled system wide by `nixos/configuration.nix` and later rebuilds no longer need `NIX_CONFIG`.

## Rebuild
After editing any file in this repo.
```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#laptop
```

A flake only sees files that git tracks. Editing a file already in the repo is enough, but a file you add must be `git add`ed before `nixos-rebuild` will see it.

## Keyboard Shortcuts
| Application | Shortcut | Action |
| --- | --- | --- |
| Spotify | <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>Space</kbd> | Play / pause |
| Spotify | <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>→</kbd> | Next track |
| Spotify | <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>←</kbd> | Previous track |

## Manual Configuration
### NordVPN
NordVPN is a paid service and requires an OpenVPN config file (`.ovpn`) that must be downloaded from the [NordVPN dashboard](https://my.nordaccount.com/) to access the service.  The `networkmanager-openvpn` plugin enabled in `nixos/configuration.nix` lets you import NordVPN profiles and toggle them from the GNOME system menu.

1. After the first rebuild that adds the plugin, restart NetworkManager so it loads the new VPN service. Otherwise activating the VPN fails with `The VPN service 'org.freedesktop.NetworkManager.openvpn' was not installed`. A reboot works too.
```bash
sudo systemctl restart NetworkManager
```

2. From the [NordVPN dashboard](https://my.nordaccount.com/), open **NordVPN** → **Manual setup** and copy your **service credentials** (a username and password separate from your account login).

3. Download an OpenVPN config file (`.ovpn`) for a server from that same page or the [server recommender](https://nordvpn.com/servers/tools/).

4. Import it: **Settings** → **Network** → **VPN** → **+** → **Import from file**, select the `.ovpn`, enter the service username and password, then **Add**.

5. Toggle the VPN on or off from the top-right system menu. Confirm it worked at [nordvpn.com/what-is-my-ip](https://nordvpn.com/what-is-my-ip/), which should show the server's location instead of your home IP. Repeat steps 3–4 with another `.ovpn` to add a different server.
