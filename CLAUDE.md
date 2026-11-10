# nepi_setup — Developer Reference

## Purpose

`nepi_setup` contains everything needed to deploy a NEPI environment: shell scripts, configuration templates, documentation, and command-line shortcuts. It covers two deployment modes (Docker Lite for trials and development machines, Docker Full for production edge devices) and a container build workflow for creating new NEPI Docker images from scratch. This submodule lives at the workspace root, not under `src/`, because it is a deployment and operations component rather than a ROS package.

## Architecture

```
nepi_setup/
├── NEPI_SOFTWARE_BUILD.md       # Developer workflow: build from source, deploy, commit
├── NEPI_DEV_PC_SETUP.md         # Set up a Linux dev PC for source-code development
├── NEPI_DOCKER_LITE_SETUP.md    # Docker Lite install (minimal, no OS service management)
├── NEPI_DOCKER_FULL_SETUP.md    # Docker Full install (production, full OS service management)
├── NEPI_DOCKER_CUSTOMIZE.md     # Runtime customization after install
├── NEPI_CONTAINER_BUILD.md      # Build a NEPI Docker container from scratch
├── scripts/                     # 33 shell scripts, orchestrated in phases
└── resources/
    ├── bash/                    # nepi_bash_utils (functions + globals), alias files
    ├── etc/                     # System config templates and runtime update scripts
    ├── configs/                 # Hardware-specific configs (Jetson, etc.)
    ├── docker/                  # Docker build resources
    ├── git/                     # Git utilities
    ├── tools/                   # Miscellaneous utilities
    ├── updates/                 # Update scripts
    └── archive/                 # Deprecated scripts (do not use)
```

## How It Works

### Deployment modes

**Docker Lite** — single orchestration script (`docker_lite_setup.sh`) that calls seven sub-scripts in sequence. Minimal footprint: adds the user to the docker group, installs bash aliases, creates the three NEPI mount points, copies config files, downloads the base Docker image, and optionally downloads sample AI models and scripts. No OS-level service management; suitable for dev machines and trial installs. Requires 60 GB free disk.

**Docker Full** — three-phase install requiring reboots between phases:
1. `docker_full_user_setup.sh` (as root) — creates the `nepihost` host OS user, configures system services
2. `docker_full_env_setup.sh` (as `nepihost`) — installs OS packages, Docker, optional CUDA
3. `docker_full_config_setup.sh` + `docker_full_init_setup.sh` — copies config templates, downloads Docker image

Full mode enables `NEPI_MANAGES_*` flags in `nepi_system_config.yaml`, which activates NEPI control over hostname, network interfaces, WiFi, SSH, time sync, and Samba sharing. Requires 40 GB disk minimum (separate partitions for `/mnt/nepi_storage`, `/mnt/nepi_docker`, `/mnt/nepi_config` are strongly recommended).

**Container build** — an eight-phase workflow documented in `NEPI_CONTAINER_BUILD.md`. Each phase runs a script inside a running container, then commits the container state (`nepicommit "phase_name"`). Phases in order: user setup → env setup 1 (base packages) → env setup 2 (Python/ML packages) → ROS install → config setup → NEPI engine build → RUI build → export final image. This workflow creates the Docker image that Lite and Full installs download.

### Configuration system

All deployment configuration is centralized in `resources/etc/nepi_system_config.yaml` (204 lines). This YAML file defines users, passwords, network settings, folder paths, hardware flags, and which OS services NEPI manages. It is loaded by `resources/etc/load_system_config.sh` (bash) and `resources/etc/load_system_config.py` (Python).

Runtime updates to system config (hostname, network, WiFi, SSH keys, users) are applied by the scripts in `resources/etc/scripts/update_etc_*.sh`. These scripts are called by `system_mgr` or by the RUI — they are not manual procedures.

### Bash utilities and aliases

`resources/bash/nepi_bash_utils` is sourced by virtually every script in this repo. It defines:
- Global path variables: `NEPI_IP`, `NEPI_HOME`, `NEPI_BASE`, `NEPI_STORAGE`, `NEPI_CONFIG`, `NEPI_DOCKER`
- Hardware detection functions: `is_valid_jetson()`, `is_valid_arm64()`, `is_valid_amd64()`
- Network check: `is_valid_internet()`
- SSH key management, folder utilities

Post-install, three alias files are sourced from `~/.bashrc`:
- `nepi_docker_aliases` — container management: `nepistart`, `nepistop`, `nepidev`, `nepilogin`, `nepicommit`, `nepiimport`, `nepiexport`, `nepienable`, `nepidisable`
- `nepi_pc_aliases` — dev workflow: `nepigithub`, `nepiclone`, `nepidpl` (deploy source to device), `nepipush`, `nepihelp`
- `nepi_system_aliases` — Full install only: `pingi`, `nipa`, `ndhcp`, `ninet`, `nclock`

### Script dependency order (Docker Lite)

```
docker_lite_setup.sh
  ├── nepi_install_check.sh   (pre-flight: internet, disk, permissions)
  ├── nepi_license_check.sh   (license verification — blocks if invalid)
  ├── docker_user_setup.sh
  ├── docker_bash_setup.sh
  ├── docker_folders_setup.sh
  ├── docker_files_setup.sh
  ├── docker_config_setup.sh
  ├── docker_image_init.sh
  └── docker_storage_init.sh
```

## Key Configuration Values

Defaults from `nepi_system_config.yaml`:

| Variable | Default | Notes |
|---|---|---|
| `NEPI_STATIC_IP` | `192.168.179.103/24` | Device static IP |
| `NEPI_ALIAS_IP_1` | `192.168.0.103/24` | First IP alias |
| `NEPI_ALIAS_IP_2` | `192.168.1.103/24` | Second IP alias |
| `NEPI_SSH_PORT` | `2222` | SSH port inside container |
| `NEPI_USER` | `nepi` | Container user |
| `NEPI_HOST_USER` | `nepihost` | Host OS user (Full only) |
| `NEPI_ADMIN_USER` | `nepiadmin` | Admin user |
| `NEPI_DEVICE_ID` | `device1` | Hostname/namespace |
| `NEPI_BASE` | `/opt/nepi` | NEPI installation root |
| `NEPI_STORAGE` | `/mnt/nepi_storage` | User data (60+ GB) |
| `NEPI_CONFIG` | `/mnt/nepi_config` | System config partition |
| `NEPI_DOCKER` | `/mnt/nepi_docker` | Docker image storage |
| `NEPI_WIRED_INTERFACE` | `eth0` | Ethernet interface name |

## Build and Dependencies

`nepi_setup` itself has no build step. It is a collection of shell scripts and config files.

Scripts assume:
- Ubuntu 18.04 or newer (Focal Fossa recommended for full Jetson support)
- arm64 (NVIDIA Jetson) or amd64 target
- `sudo` access on the target machine
- Internet connectivity at setup time (downloads Docker, ROS packages, base image)

For ROS inside the container: Noetic is installed for arm64, Melodic for amd64. This is detected and selected automatically by `ros_setup.sh` based on `NEPI_ARCH`.

For AI frameworks inside the container: `nepi_env_setup2.sh` installs PyTorch, TensorFlow, and the YOLOv5 package. CUDA installation is handled separately by `nepi_cuda_setup.sh`, which detects Jetson hardware and installs the appropriate version.

## Known Constraints and Fragile Areas

**Reboots are required between phases in Docker Full.** The setup guides are explicit about this. Skipping a reboot between phases leaves the system in an inconsistent state (e.g., group membership changes not active, services not restarted). There is no automated phase-completion check.

**Default passwords are hardcoded and documented publicly.** `nepi`, `nepiadmin`, and `nepi` (for `nepihost`) are the defaults and are not secret. Changing them requires modifying `nepi_system_config.yaml` and searching for any hardcoded occurrences in the scripts. The NEPI_DOCKER_CUSTOMIZE.md describes the `nepiconfig` menu for changing passwords post-install.

**`eth0` is the hardcoded default wired interface** in `nepi_system_config.yaml`. Devices with a different interface name (e.g., `enp3s0`, `ens5`) will need this value updated before the network management scripts run correctly.

**`nepi_license_check.sh` is sourced by every script and blocks execution if it fails.** If the license check mechanism is not satisfied on the target system, no setup script will proceed. This is intentional but can be surprising in new environments.

**`resources/archive/` contains deprecated scripts** that are not maintained. Do not use them. Their presence is for historical reference only.

**The container build workflow is manual and sequential.** There is no CI pipeline for container builds. Each `nepicommit` checkpoint must be run manually after verifying the previous phase. A failed phase mid-build may require starting from the last good commit.

**`nepi_bash_utils` defines `NEPI_IP = 192.168.179.103`** as a hardcoded constant used by `nepidpl` (deploy source to device) and SSH shortcuts. This must match the actual device IP on the developer's network. Change it in `nepi_bash_utils` or override it in `~/.bashrc` before running deployment commands.

**Docker Lite and Full are mutually exclusive on the same machine.** Full setup creates the `nepihost` user and activates OS-level service management. Running Lite setup afterward will conflict with those configurations.

## Decision Log

- 2026-03 — CLAUDE.md created — Initial developer reference, Claude Code authoring pass.
