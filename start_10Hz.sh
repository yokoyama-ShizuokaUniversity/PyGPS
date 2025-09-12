#!/usr/bin/env bash

set -euo pipefail

DEVICE="/dev/serial0"
INIT_BAUD=9600
TARGET_BAUD=115200
UPDATE_HZ=10
DRY_RUN=0
RESTART_GPSD=1

usage() {
    cat <<EOF
Usage: $0   [--device DEV] [--init-baud N] [--target-baud N] [--update-hz N]
            [--no-restart-gpsd] [--dry-run] [--help]

Examples:
    $0 --device /dev/ttyAMA0 --init-baud 38400 --update-hz 5 --no-restart-gpsd
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--device)        DEVICE="${2:-}"; shift 2;;
        -ib|--init-baud)    INIT_BAUD="${2:-}"; shift 2;;
        -tb|--target-baud)  TARGET_BAUD="${2:-}"; shift 2;;
        -hz|--update-hz)    UPDATE_HZ="${2:-}"; shift 2;;
        -n|--no-restart-gpsd)  RESTART_GPSD=0; shift;;
        -dr|--dry-run)      DRY_RUN=1; shift;;
        -h|--help)      usage; exit 0;;
        *)              echo "Unknown option: $1"; usage; exit 1;;
    esac
done

if [[ -L "$DEVICE" ]]; then
    RESOLVED="$(readlink -f "$DEVICE" || true)"
else
    RESOLVED="$DEVICE"
fi

say() { echo "[$(date +%H:%M:%S)] $*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Need: $1"; exit 1; }; }

gpsd_baud() {
    local p
    p="$(pidof gpsd || true)"
    if [[ -n "$p" ]]; then
        tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null | sed 's/  */ /g' | \
            awk '{for (i=1;i<=NF;i++) if ($i=="-s" && (i+1)<=NF) {print $(i+1); exit}}'
    fi
}

who_uses_dev() {
    need_cmd fuser
    fuser -v "$RESOLVED" 2>/dev/null || true
}

pmtk_line() {
    local payload="$1"
    local i c cs=0
    for (( i=0; i<${#payload}; i++ )); do
        printf -v c "%d" "'${payload:$i:1}"
        cs=$(( cs ^ c ))
    done
    printf "\$%s*%02X\r\n" "$payload" "$cs"
}

send_updatehz_pmtk() {
   case "$UPDATE_HZ" in
       1)   sendline='$PMTK220,1000*1F\r\n' ;;
       5)   sendline='$PMTK220,200*2C\r\n' ;;
       10)  sendline='$PMTK220,100*2F\r\n' ;;
       *)   echo "Unsupported --update-hz: $UPDATE_HZ (supported: 1,5,10)"; exit 1 ;;
   esac
   send_pmtk "$sendline"
}

send_baudrate_pmtk() {
    case "$TARGET_BAUD" in
        9600)   sendline='$PMTK251,9600*17\r\n' ;;
        115200) sendline='$PMTK251,115200*1F\r\n' ;;
        *)      echo "Unsupported --target-baud: $TARGET_BAUD (supported: 9600,115200)"; exit 1 ;;
    esac
    send_pmtk "$sendline"
}

send_pmtk() {
    local sendline=$1
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf "[DRY] -> %s" "$sendline"
    else
        printf '%b' "$sendline" > "$RESOLVED"
    fi
}

# Start Setting
need_cmd stty
need_cmd systemctl
need_cmd fuser
if [[ ! -e "$RESOLVED" ]]; then
    echo "Device not found: $DEVICE (resolved: $RESOLVED)" >&2
    exit 1
fi

say "Device: $DEVICE (resolved to $RESOLVED)"
if [[ -L "$DEVICE" ]]; then
    say "Symlink target: $RESOLVED"
fi

# gpsd status
GPSD_ACTIVE="$(systemctl is-active gpsd 2>/dev/null || true)"
GPSD_SOCKET_ACTIVE="$(systemctl is-active gpsd.socket 2>/dev/null || true)"
say "gpsd: $GPSD_ACTIVE  | gpsd.socket: $GPSD_SOCKET_ACTIVE"
GB="$(gpsd_baud || true)"
if [[ -n "$GB" ]]; then
    say "gpsd reported baud (-s): ${GB}"
else
    say "gpsd baud (-s) not found (maybe default/autodetect)."
fi

USERS="$(who_uses_dev)"
if [[ -n "$USERS" ]]; then
    say "Process using $RESOLVED:"
    echo "$USERS"
fi

if systemctl is-active --quiet gpsd || systemctl is-active --quiet gpsd.socket; then
    say "Stopping gpsd/gpsd.socket ..."
    [[ "$DRY_RUN" -eq 1 ]] || sudo systemctl stop gpsd.socket gpsd || true
fi
USERS_AFTER="$(who_uses_dev)"
if [[ -n "$USERS_AFTER" ]]; then
    say "WARNING: $RESOLVED is still in use by:"
    echo "$USERS_AFTER"
    say "Close the above programs and return."
    exit 1
fi

# Set initial baudrate
say "Setting tty to INIT_BAUD=${INIT_BAUD}"
stty -F "$RESOLVED" "${INIT_BAUD}" raw -echo -ixon -ixoff cs8 -cstopb -parenb

say "Sending PMTK251 (baud -> ${TARGET_BAUD})"
send_baudrate_pmtk

say "Reconfiguring tty to TARGET_BAUD=${TARGET_BAUD}"
stty -F "$RESOLVED" "${TARGET_BAUD}" raw -echo -ixon -ixoff cs8 -cstopb -parenb

say "Sending PMTK220 (update rate -> ${UPDATE_HZ} Hz)"
send_updatehz_pmtk

say "Reading back a few lines for ACK (3s)..."
timeout 3s head -n 20 < "$RESOLVED" || true

# Restart gpsd
if [[ "$RESTART_GPSD" -eq 1 ]]; then
    say "Starting gpsd (socket activation)..."
    sudo systemctl enable --now gpsd.socket gpsd >/dev/null 2>&1 || \
        sudo systemctl enable --now gpsd 2>&1 || true

    say "gpsd status:"
    systemctl --no-pager --full status gpsd 2>/dev/null | sed -n '1,8p' || true

    if [[ -r /etc/default/gpsd ]]; then
        say "/etc/default/gpsd:"
        sed -n '1,120p' /etc/default/gpsd
    fi
else
    say "Skipped restarting gpsd (user --no-restart-gpsd to keep it stopped)."
fi

say "Done."
