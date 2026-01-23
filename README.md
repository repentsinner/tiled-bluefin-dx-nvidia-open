# Tiling Bluefin-DX (Experimental)

A custom [bootc](https://github.com/bootc-dev/bootc) image based on Universal Blue's Bluefin-DX, replacing GNOME with tiling window managers for a keyboard-driven Wayland workflow with Nvidia GPU support.

**Available Compositors**: Hyprland, Niri (selectable at login)

**Wayland-Only**: This is a pure Wayland build with no XWayland/X11 compatibility layer. All applications must support native Wayland.

## Why Hyprland? (Migration from Sway)

This project originally used Sway but migrated to Hyprland due to **critical HiDPI compatibility issues**:

- **Sway lacks wp-fractional-scale-v1 support**: Sway does not implement the Wayland fractional scaling protocol (`wp-fractional-scale-v1`), limiting it to integer-only scaling (1x, 2x, etc.)
- **Integer scaling is unusable on modern displays**: Users must choose between tiny UI elements (1x) or comically oversized interfaces (2x) with no middle ground
- **Hyprland implements the protocol**: Hyprland fully supports `wp-fractional-scale-v1`, enabling proper fractional scaling (1.25x, 1.5x, 1.75x, etc.)
- **No viable workarounds**: Community workarounds for Sway (xwayland scaling hacks, pango overrides) are unreliable and break application rendering

**DO NOT suggest switching back to Sway without solving the HiDPI problem first.** This is a blocker, not a preference.

## Project Goals

This image aims to provide:

1. **Reliability**: A stable, well-supported tiling window manager that works consistently
2. **Visual Quality**: Proper high-DPI support and modern aesthetics (not terminal-era visuals)
3. **Nvidia Compatibility**: Full GPU support for Nvidia hardware
4. **Developer Workflow**: Preserve Bluefin-DX's development tools while adding tiling capabilities
5. **Keyboard-Driven**: Efficient tiling window management

## Key Features

### Excellent High-DPI Support
Hyprland provides superior HiDPI scaling with proper fractional scaling support, ensuring crisp text and UI elements on modern displays.

### Master Layout
Native master-stack tiling layout that intelligently manages window placement, perfect for focused development workflows.

## What This Image Does

This image transforms Bluefin-DX into a tiling window manager system by:

### GNOME Removal
Removes GNOME Shell, GDM, Mutter, and all GNOME Shell extensions to create a minimal base for tiling compositors.

### Compositor Installation
Installs both **Hyprland** and **Niri** compositors, selectable at the login screen:

- **Hyprland**: Dynamic tiling compositor with animations and effects
- **Niri**: Scrollable tiling compositor with a unique infinite canvas workflow

Shared environment includes:
- **Status Bar**: Waybar
- **Application Launcher**: Fuzzel
- **Terminal**: Ptyxis (GTK4, GPU-accelerated, native container integration)
- **Lock Screen**: Hyprlock (Hyprland), swaylock (Niri)
- **Idle Management**: hypridle
- **Notifications**: Mako
- **Screenshots**: Grim and Slurp
- **Screen Recording**: wf-recorder
- **Wallpaper**: swww
- **File Manager**: Thunar
- **Display Management**: wdisplays
- **Utilities**: wl-clipboard, cliphist, pamixer, brightnessctl
- **IDE**: Google Antigravity

### Display Manager
- Uses **greetd** with **tuigreet** instead of GDM
- Session selector allows choosing between Hyprland and Niri at login
- Remembers your last session choice
- Properly configured for OSTree-based systems using sysusers.d and tmpfiles.d
- Full Nvidia environment variables configured

### Theming
- Default GTK theme set to **adw-gtk3-dark** for both GTK 3 and GTK 4
- Dark theme preference enabled by default
- Configuration applied via `/etc/skel` for all new users

### System Configuration
- **Polkit agent**: lxpolkit configured to autostart with the compositor
- **Portals**: xdg-desktop-portal-hyprland and xdg-desktop-portal-gtk for proper Wayland integration
- **Input settings**:
  - Caps Lock remapped to Control
  - Natural scrolling enabled for touchpads
  - Custom keyboard and mouse configuration
- **Podman socket**: Enabled by default
- **Layout**: Master-stack layout configured as default
- **Nvidia optimizations**: Full environment variable configuration for optimal GPU performance

## Identified Requirements

Based on the current setup, any replacement compositor must support:

### Core Requirements
- **Nvidia GPU compatibility**: Must work with proprietary Nvidia drivers
- **Wayland-only**: Pure Wayland, no XWayland/X11 compatibility (X11-only apps will not work)
- **HiDPI scaling**: Proper fractional scaling and readable text/UI elements
- **OSTree compatibility**: Works with immutable/atomic OS structure

### Integration Requirements
- **Display Manager**: Works with greetd/tuigreet ✓
- **Desktop Portals**: Compatible with xdg-desktop-portal-hyprland ✓
- **Session Management**: Launched via Wayland session files ✓
- **Polkit Integration**: Supports polkit agents for privilege escalation ✓

### User Experience
- **Tiling Management**: Automatic window tiling with keyboard controls
- **Multi-monitor**: Robust multi-display support
- **Configuration**: Declarative config files (no GUI-only settings)
- **Input Remapping**: Custom keyboard layouts (e.g., Caps→Ctrl)

### Development Workflow (Inherited from Bluefin-DX)
- Container tooling compatibility (Podman, distrobox)
- Terminal emulator support
- Screen capture/recording tools
- Visual theming capabilities (GTK apps)

## Installation

From a bootc-based system (Bazzite, Bluefin, Aurora, etc.):

```bash
sudo bootc switch ghcr.io/<username>/hyprland-bluefin-dx-nvidia-open
sudo reboot
```

## Post-Installation Setup

### Tailscale VPN (Optional)

Tailscale is pre-installed and enabled. To set up the GUI:

1. **Set your user as operator** (allows GUI control without sudo):
   ```bash
   sudo tailscale set --operator=$USER
   ```

2. **Install trayscale GUI** (already configured to auto-start):
   ```bash
   flatpak install flathub dev.deedles.Trayscale
   ```

The trayscale icon will appear in your system tray for easy VPN management.

### WireGuard VPN

WireGuard tools are pre-installed. Configure VPN connections via NetworkManager:
- Use `nmcli` for CLI configuration
- Or install `nm-connection-editor` for GUI setup

WireGuard status is shown in the waybar status bar.

## Configuration

### Hyprland
Customize by editing `~/.config/hypr/hyprland.conf`. This file will be sourced by the system configuration and can override any settings.

### Niri
Customize by creating `~/.config/niri/config.kdl`. See the [Niri wiki](https://github.com/YaLTeR/niri/wiki) for configuration options.

### Key Bindings (Hyprland Default)

- **Super + Enter**: Launch terminal (ptyxis)
- **Super + D**: Application launcher (fuzzel)
- **Super + Q**: Close window
- **Super + M**: Exit Hyprland
- **Super + E**: File manager (Thunar)
- **Super + V**: Toggle floating
- **Super + H/J/K/L**: Move focus (vim keys)
- **Super + 1-9**: Switch workspace
- **Super + Shift + 1-9**: Move window to workspace
- **Print**: Screenshot selection
- **Shift + Print**: Screenshot full screen

All keybindings can be customized in your user configuration file.

## Community Resources

- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc Discussion Forums](https://github.com/bootc-dev/bootc/discussions)
