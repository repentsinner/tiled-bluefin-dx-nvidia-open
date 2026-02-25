# SPEC: Tilefin-DX System Image

## Purpose

Tilefin-DX is an immutable bootc/OSTree system image based on
Bluefin-DX. It replaces GNOME with the Niri tiling compositor for a
keyboard-driven Wayland desktop on Nvidia hardware.

The image provides desktop infrastructure only: compositor, session
management, display manager, theming, and system services. User tools
and development toolchains belong in distrobox containers or user-space
installers — not in the image.

## Base image

`ghcr.io/ublue-os/bluefin-dx-nvidia-open:gts`

Bluefin-DX provides Fedora, Nvidia drivers (open kernel modules),
Podman, distrobox, VS Code, and container development tooling. This
image layers Niri and supporting Wayland infrastructure on top.

## Image boundary

The image shall contain only software that meets at least one of:

- Required before or during login (greetd, compositor, session wrapper).
- Required by the desktop session (waybar, clipboard, lock screen).
- A system service or kernel-level integration (libvirt, IOMMU, podman).
- Desktop applications tightly coupled to the session (file manager,
  terminal, polkit agent).

Software that runs on demand with no session dependency belongs
elsewhere:

| Delivery | For |
|---|---|
| **Userbox** (distrobox, pre-built OCI) | CLI tools, shell utilities, dev toolchains |
| **Flatpak** | Sandboxed GUI apps |
| **Native installer** (`~/.local/bin`) | Self-updating vendor CLIs (e.g., Claude Code) |

## Sections

### S1: GNOME removal

*Status: complete — PR #1, 2024-10-15*

The image removes GNOME Shell, GDM, Mutter, Nautilus, and all GNOME
Shell extensions. These are replaced by Niri and supporting Wayland
components.

Rationale: Niri cannot coexist with GNOME Shell. GDM is replaced by
greetd. Nautilus is replaced by Thunar.

### S2: Homebrew removal

*Status: complete — PR #1, 2024-10-15*

Bluefin-DX ships Homebrew integration (profile scripts, systemd units,
presets). The image removes all Homebrew artifacts.

Rationale: Homebrew's single-user macOS model conflicts with immutable,
multi-user systems. Distrobox and Flatpak cover all use cases without
`/home/linuxbrew` pollution.

### S3: Niri compositor

*Status: complete — PR #1, 2024-10-15*

The image installs a custom niri fork (niri-desaturate) from a GitHub
release RPM until the desaturate window rule merges upstream.

The session launches via a wrapper script (`niri-tilefin-session`) that
sets `SSH_AUTH_SOCK` before starting niri. A custom `.desktop` file
registers the session with greetd.

System-wide config lives at `/etc/niri/config.kdl`. Users override via
`~/.config/niri/config.kdl`.

### S4: Wayland environment

*Status: complete — PR #1, 2024-10-15*

The image provides a complete Wayland desktop environment:

- **Status bar**: Waybar with system-wide config at `/etc/xdg/waybar/`.
  Custom modules for update checking and notification indicators live at
  `/usr/share/tilefin/scripts/`.
- **Lock screen**: Hyprlock with system config at `/etc/xdg/hypr/`.
- **Idle management**: Hypridle with system config at `/etc/xdg/hypr/`.
- **Notifications**: Mako. No XDG fallback path — uses `/etc/skel/`.
- **Wallpaper**: swww.
- **Clipboard**: wl-clipboard, wl-clip-persist, cliphist.
- **Screenshots**: grim, slurp, wf-recorder.
- **App launcher**: Fuzzel.
- **Logout**: wlogout, nwg-bar, compositor-exit script.
- **Desktop portal**: xdg-desktop-portal-gtk (replaces GNOME backend).

### S5: Display manager

*Status: complete — PR #1, 2024-10-15*

greetd with tuigreet replaces GDM. Config at `/etc/greetd/config.toml`.
A tmpfiles.d entry creates `/var/lib/greetd` at boot (the package's
tmpfiles.d only sets ownership, doesn't create the directory).

### S6: Desktop applications

*Status: complete — PR #1, 2024-10-15*

- **Terminal**: Ptyxis (GTK4, native distrobox integration).
- **File manager**: Thunar with gvfs and tumbler.
- **Media**: mpv.
- **Polkit**: lxpolkit.
- **Utilities**: rofimoji, network-manager-applet, wdisplays.
- **Flatpaks**: Bitwarden (password manager), Trayscale (Tailscale GUI).

### S7: Theming

*Status: complete — PR #1, 2024-10-15*

adw-gtk3-dark for GTK 3/4. System-wide via `/etc/gtk-{3,4}.0/`. GTK 2
via `/etc/skel/.gtkrc-2.0`. Fonts: Fira Code, FontAwesome, Noto Emoji.

### S8: System services

*Status: complete — PR #1, 2024-10-15*

Enabled at build time:

- `podman.socket` — container management.
- `tailscaled.service` — Tailscale VPN.
- `libvirtd.socket` — VM management (socket-activated).
- `greetd.service` — display manager.
- `rpm-ostreed-automatic.timer` — auto-stage image upgrades.

### S9: Virtualization

*Status: complete — PR #1, 2024-10-15*

Full KVM/QEMU/libvirt stack for Windows VM hosting with Looking Glass
GPU passthrough support:

- libvirt, qemu-kvm, virt-manager, virt-install.
- edk2-ovmf (UEFI firmware), swtpm (TPM emulation for Windows 11).
- looking-glass-client (low-latency framebuffer, from COPR).
- virtiofsd (fast file sharing).
- Polkit rule: wheel group can manage VMs without extra groups.
- IOMMU kernel args enabled via `bootc kargs.d`.

### S10: Wayland environment config

*Status: complete — PR #1, 2024-10-15*

- Electron apps forced to native Wayland via
  `/etc/environment.d/electron-wayland.conf`.
- System-wide Flatpak overrides enable Wayland socket and Electron
  Wayland flags.
- Trayscale Flatpak gets filesystem access to `/run/tailscale`.

### S11: Shell aliases

*Status: complete — PR #1, 2024-10-15*

`/etc/profile.d/cli-aliases.sh` provides bash aliases for eza, zoxide
init, and starship init. These resolve at runtime against whatever is on
`$PATH` — they work whether the binary comes from the image or a
distrobox export.

### S12: Userbox — move user tools to distrobox

*Status: in progress*

#### Problem

The image bakes in 7 CLI tools and 1 GUI app with no session-startup
dependencies: `gh`, `chezmoi`, `direnv`, `zoxide`, `starship`, `eza`,
`bws`, `antigravity`. Including them causes image rebuilds for tool
updates and blurs the boundary between OS and personal environment.

#### Design

User tools move to a pre-built OCI container image consumed by
distrobox. The container is ephemeral — recreated from the image on
each login via a systemd user unit. No drift from the declaration.

See [repentsinner/userbox](https://github.com/repentsinner/userbox) for
the Containerfile and CI. This repo covers only the image-side changes.

Three repos, three concerns:

| Repo | Contains | Lifecycle |
|---|---|---|
| **tiled-bluefin-dx-nvidia-open** | OS image, ujust recipes, shell aliases, skel default | Rare |
| **repentsinner/userbox** | Containerfile for user tools image | Frequent |
| **chezmoi dotfiles** | `.ini`, systemd unit, shell config | Personal |

##### Bootstrap and graceful degradation

A fresh system has no chezmoi (it lives inside the userbox) and no
userbox `.ini` (it's managed by chezmoi). This cycle breaks via three
layers of the same file, each more specific than the last:

1. **Skel default** — the image ships
   `/etc/skel/.config/distrobox/userbox.ini` with a default image path.
   Every new user account gets a working `.ini` at account creation.
2. **ujust override** — `ujust setup-userbox [image]` accepts an
   optional image argument, rewrites the `.ini`, and runs assembly.
   Useful for first boot or switching images.
3. **Chezmoi steady-state** — once the userbox is running, chezmoi owns
   the `.ini` going forward. Changes flow from dotfiles.

All shell aliases and hooks are guarded with `command -v`. A system
with no userbox functions normally — it just lacks CLI tools.

#### R12.1: Image does not contain user tools

The image does not install `gh`, `chezmoi`, `direnv`, `zoxide`,
`starship`, `eza`, `bws`, or `antigravity`. No COPR repos, curl
blocks, or package arrays exist for these tools in the build script.

#### R12.2: Shell aliases degrade gracefully

Every alias and shell hook in `cli-aliases.sh` is guarded with
`command -v`. When a tool is absent (no userbox, or userbox not yet
assembled), the alias is silently skipped. No `command not found`
errors on a fresh system.

#### R12.3: direnv shell hook

`cli-aliases.sh` includes a guarded direnv hook for bash:

```bash
if [[ $- == *i* ]] && command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi
```

Fish hook belongs in chezmoi-managed `~/.config/fish/config.fish`, not
in this image.

#### R12.4: Skel default userbox.ini

The image ships `/etc/skel/.config/distrobox/userbox.ini`. Every new
user account receives a working distrobox declaration at account
creation.

```ini
[userbox]
image=ghcr.io/repentsinner/userbox:latest
nvidia=true
pull=true
replace=true
start_now=true
exported_bins="/usr/bin/gh /usr/bin/chezmoi /usr/bin/direnv /usr/bin/zoxide /usr/bin/starship /usr/bin/eza /usr/bin/bws"
exported_bins_path="~/.local/bin"
```

`nvidia=true` matches the base image (`bluefin-dx-nvidia-open`), which
ships Nvidia open kernel modules and the container toolkit. The userbox
inherits GPU access for tools that need it.

Rationale: breaks the chezmoi↔userbox bootstrap cycle. Chezmoi lives
inside the userbox, so it cannot seed its own `.ini`. The skel file
provides a working default; chezmoi overwrites it once available.

#### R12.5: ujust setup-userbox recipe

`tilefin.just` provides a `setup-userbox` recipe that assembles the
userbox container from `~/.config/distrobox/userbox.ini`.

When an optional image argument is provided, the recipe rewrites the
`image=` line in the `.ini` before assembly. This supports switching
images or overriding the skel default without chezmoi.

The recipe has no knowledge of which tools the container provides.

#### R12.6: Systemd user unit for auto-assembly (chezmoi)

A systemd user service (`~/.config/systemd/user/userbox.service`) runs
`distrobox assemble create --replace` on login. Managed by chezmoi.

```ini
[Unit]
Description=Assemble userbox distrobox container

[Service]
Type=oneshot
ExecStart=/usr/bin/distrobox assemble create --replace --file %h/.config/distrobox/userbox.ini
RemainAfterExit=true

[Install]
WantedBy=default.target
```

The service starts after login and does not block the GUI session. With
a cached image, container assembly takes ~10 seconds in the background.

### S13: Sunshine streaming server

*Status: not started*

The image shall include Sunshine for game/desktop streaming.

Sunshine requires direct GPU access (NVENC encoding), KMS/DRM capture,
udev rules for virtual input devices, and a systemd service. These are
system-level integrations that cannot run from a distrobox.

*Requirements to be specified after research into Sunshine's Fedora
packaging and Niri/Wayland compatibility.*

### S14: VS Code

*Status: complete — PR #1, 2024-10-15*

VS Code ships in the bluefin-dx base image. The build updates it to the
latest version from Microsoft's repo. VS Code is a host application
that attaches to containers — it does not belong in the userbox.

## Out of scope

- **User dotfiles**: Managed by chezmoi in a separate repo. This image
  provides system-wide defaults via `/etc/skel/`, `/etc/xdg/`, and
  `/etc/profile.d/`. Users override in `~/.config/`.
- **Userbox Containerfile**: Lives in repentsinner/userbox. This spec
  covers the image-side changes only (R12.1–R12.5).
- **Flutter/FVM**: Future addition to the userbox Containerfile.
- **Flatpak apps beyond Bitwarden/Trayscale**: User-installed via
  `flatpak install --user`.
