# CPU Temperature Limiter

A Linux system tool that monitors CPU temperature in real time and dynamically throttles CPU frequency to stay below a user-defined threshold. Consists of a root daemon and a modern GTK4 + libadwaita UI with live history graphs.

![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![Python](https://img.shields.io/badge/python-3.10%2B-blue)

## Features

- **Background daemon** — monitors CPU temperature every 5 seconds and adjusts `scaling_max_freq` in 200 MHz steps to keep below threshold
- **Live history graph** — dual-axis Cairo chart showing temperature, frequency limit, and current frequency over 1h / 6h / 24h windows
- **Event markers** — vertical indicators on the graph wherever a throttle or restore event occurred
- **Hover crosshair** — mouse-over shows exact temp, freq, and limit values at any point in time
- **4 stat cards** — CPU Temp, Freq Limit, Current Freq, Fan RPM — colour-coded live
- **Instant threshold control** — spinner in the UI signals the daemon via SIGHUP, no restart needed
- **7-day SQLite history** — persists across reboots, loaded on UI startup
- **Unix socket IPC** — daemon pushes structured JSON telemetry to connected UI clients every 5s
- **System tray** — close to tray, reopen from tray icon
- **Systemd integration** — daemon runs as a service, auto-restarts on failure
- **Autostart** — UI launches on login via XDG autostart

## Screenshots

> UI shows live temperature and frequency history with event markers and hover tooltip.

## Requirements

- Linux with `/sys/class/thermal/` and `/sys/devices/system/cpu/*/cpufreq/`
- Python 3.10+
- GTK 4 + libadwaita 1.x
- psutil
- systemd

## Installation

```bash
git clone https://github.com/BovinZero98/cpu-temp-limiter.git
cd cpu-temp-limiter
sudo ./install.sh
```

The installer will:
1. Install Python/GTK4/AppIndicator dependencies via apt
2. Copy daemon and UI to `/usr/local/bin/`
3. Install and start the systemd service
4. Create the `temp-limiter` group and add your user to it
5. Install desktop autostart entry and icon

> You may need to log out and back in for group membership to take effect.

## Usage

The daemon starts automatically via systemd. The UI auto-starts on login, or run manually:

```bash
temp-limiter-ui
```

### UI controls

| Control | Description |
|---|---|
| **1h / 6h / 24h** | Switch history time window |
| **Threshold spinner** | Set temperature ceiling — takes effect on daemon immediately |
| **Hover over chart** | See exact values at any point in time |
| **Close button** | Hides to system tray |

### Daemon management

```bash
systemctl status temp-limiter     # check status
systemctl restart temp-limiter    # restart
journalctl -u temp-limiter -f     # live logs
```

## How It Works

### Throttling Logic

Every 5 seconds the daemon:
1. Reads CPU package temperature via `psutil` (falls back to sysfs thermal zones)
2. If temp > threshold: reduces `scaling_max_freq` by 200 MHz across all cores
3. If temp < threshold − 5°C (hysteresis): increases `scaling_max_freq` by 200 MHz until restored
4. Writes a telemetry row to SQLite and broadcasts JSON over the Unix socket

### IPC Architecture

```
Daemon (root)  ──── Unix socket (/run/temp-limiter/daemon.sock) ────▶  UI (user)
               ──── SQLite WAL  (/var/lib/temp-limiter/history.db) ──▶  UI (history on startup)
UI             ──── SQLite config table + SIGHUP ────────────────────▶  Daemon (threshold change)
```

### File Layout

| Path | Purpose |
|---|---|
| `/usr/local/bin/temp-limiter-daemon` | Daemon executable |
| `/usr/local/bin/temp-limiter-ui` | UI executable |
| `/etc/temp-limiter.conf` | Config (threshold, writable by `temp-limiter` group) |
| `/run/temp-limiter/daemon.sock` | Live telemetry socket |
| `/run/temp-limiter/daemon.pid` | Daemon PID (for SIGHUP) |
| `/var/lib/temp-limiter/history.db` | SQLite WAL history database |
| `/var/log/temp-limiter.log` | Plain text log |
| `/etc/systemd/system/temp-limiter.service` | Systemd unit |

## Configuration

`/etc/temp-limiter.conf` (INI format):

```ini
[default]
threshold = 60
```

The UI writes threshold changes directly to the daemon's SQLite config table and sends SIGHUP — no file editing needed.

## License

MIT
