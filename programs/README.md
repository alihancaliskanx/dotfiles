# programs/

Install scripts for the software on this machine that no package manager
handles. Nothing here runs on its own — `install.sh` never calls into this
folder, and `link.sh` does not symlink it. You run one when you need that
program back.

Everything in here is a program that is either behind a vendor login, pinned to
a version the repos do not carry, or shipped only as a tarball or an AppImage.
Anything that pacman, the AUR or flatpak can install is in `install.sh` and
`extras/pacman-explicit.txt` instead, which is where it belongs.

| Script              | What it installs | Why it is not a package |
|---------------------|------------------|-------------------------|
| `matlab.sh`         | MATLAB R2025b via MathWorks' own `mpm`, plus the two Arch fixes the activation window needs | there is no MATLAB package; the login window needs gtk2 and gnutls 3.8.9 dropped into MATLAB's own lib directory |
| `stm32cubeide.sh`   | STM32CubeIDE into `~/st`, from an installer you download from st.com | the download is behind a my.st.com login |
| `arm-gcc.sh`        | `gcc-arm-none-eabi` **10-2020-q4-major** into `/opt` | ArduPilot pins this release; the repo package tracks the newest one |
| `arduino-cli.sh`    | `arduino-cli` into `~/.local/bin` | a single static binary, taken straight from the upstream release |
| `mavproxy.sh`       | MAVProxy + pymavlink into `~/.local` | PyPI only, and Arch's Python needs `--break-system-packages` to allow it |
| `plotjuggler.sh`    | PlotJuggler AppImage into `~/Applications` | the AUR build breaks on every Qt/ROS bump |
| `sonarview.sh`      | SonarView AppImage into `~/Applications` | Cerulean Sonar ship an AppImage and nothing else |

Every script takes `-h` for its full notes, is safe to run twice, and honours
the same proxy variable as `install.sh`:

```sh
./programs/arm-gcc.sh -h
PROXY=192.168.49.1:8000 ./programs/matlab.sh
```

The header comment of each script is the real documentation — that is where the
reason for every workaround is written down, which is the whole point of keeping
them here rather than in shell history.
