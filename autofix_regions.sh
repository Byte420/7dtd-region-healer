#!/bin/bash

# === CONFIGURATION ===

# Customize these settings before running
# ----------------------------
# Base Linux username used for paths
LINUX_USER="sdtdserverbf1"

# Server/world name (used for region save paths)
WORLD_NAME="Scabfoundry"

# Webhook URL for Discord notifications
WEBHOOK_URL="https://discord.com/api/webhooks/your_url_here"

# Heartbeat interval in seconds
HEARTBEAT_INTERVAL=10

# Region backup frequency (in minutes) and retention count
REGION_BACKUP_INTERVAL_MINUTES=60
REGION_BACKUP_RETENTION_COUNT=24

# Backup recovery depth (1 = most recent)
CORRUPT_REPLACE_LOOKBACK_COUNT=1

# Server restart attempt settings
MAX_RESTART_ATTEMPTS=5
RESTART_WAIT_SECONDS=15

# Timeout before killing stuck processes (not used directly, but reserved for future logic)
PROCESS_KILL_TIMEOUT=60
# ----------------------------

# === DYNAMIC PATHS ===
BASE_DIR="/home/$LINUX_USER"
REGION_DIR="$BASE_DIR/.local/share/7DaysToDie/Saves/$WORLD_NAME/$WORLD_NAME/Region"
REGION_BACKUP_DIR="$BASE_DIR/region_backups"
LOG_FILE="$BASE_DIR/log/console/sdtdserver-console.log"
AUTOMATION_LOG_DIR="$BASE_DIR/log/automation"
AUTOMATION_LOG_FILE="$AUTOMATION_LOG_DIR/autofix.log"
SDTDSERVER_CMD="$BASE_DIR/sdtdserver"

# === INIT ===
mkdir -p "$AUTOMATION_LOG_DIR"
mkdir -p "$REGION_BACKUP_DIR"
last_backup_time=0
last_action="idle"

log() {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $*" | tee -a "$AUTOMATION_LOG_FILE"
}

send_discord() {
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$1\"}" \
         "$WEBHOOK_URL" >/dev/null 2>&1
}

maybe_backup_region() {
    now=$(date +%s)
    interval=$((REGION_BACKUP_INTERVAL_MINUTES * 60))

    if (( now - last_backup_time >= interval )); then
        TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
        BACKUP_PATH="$REGION_BACKUP_DIR/region_$TIMESTAMP"
        cp -a "$REGION_DIR" "$BACKUP_PATH"
        log "[+] Region backup created at: $BACKUP_PATH"

        # Prune old backups
        ls -dt "$REGION_BACKUP_DIR"/region_* | tail -n +$((REGION_BACKUP_RETENTION_COUNT + 1)) | xargs -r rm -rf
        log "[*] Cleanup: Retained only last $REGION_BACKUP_RETENTION_COUNT backups"

        last_backup_time=$now
        last_action="backup"
    fi
}

restart_server() {
    attempt=1
    while (( attempt <= MAX_RESTART_ATTEMPTS )); do
        log "[*] Attempting to start 7DTD server (Attempt $attempt/$MAX_RESTART_ATTEMPTS)..."
        send_discord ":hourglass_flowing_sand: Attempt $attempt to start 7DTD server..."
        $SDTDSERVER_CMD start
        sleep $RESTART_WAIT_SECONDS

        if pgrep -f "7DaysToDieServer.x86_64" >/dev/null; then
            log "[+] Server successfully started."
            send_discord ":white_check_mark: 7DTD server started successfully."
            return 0
        fi

        log "[!] Server did not start successfully."
        ((attempt++))
    done

    log "[x] Failed to start server after $MAX_RESTART_ATTEMPTS attempts."
    send_discord ":x: Failed to start 7DTD server after $MAX_RESTART_ATTEMPTS attempts. Manual intervention required."
    return 1
}

kill_stuck_server_if_needed() {
    if pgrep -f "7DaysToDieServer.x86_64" >/dev/null; then
        log "[!] Detected stuck server process. Backing up before killing."
        TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
        BACKUP_PATH="$REGION_BACKUP_DIR/region_pre_kill_$TIMESTAMP"
        cp -a "$REGION_DIR" "$BACKUP_PATH"
        log "[+] Backup of current Region created at: $BACKUP_PATH"
        send_discord ":floppy_disk: Backup made before killing stuck server at \`$BACKUP_PATH\`"

        pkill -f "7DaysToDieServer.x86_64"
        sleep 5
        if pgrep -f "7DaysToDieServer.x86_64" >/dev/null; then
            kill -9 $(pgrep -f "7DaysToDieServer.x86_64")
            log "[x] Force killed stuck 7DTD server process."
            send_discord ":warning: Force killed stuck 7DTD server process."
        else
            log "[+] Gracefully stopped stuck server."
        fi
    fi
}

# === STARTUP ===

log "[+] Starting 7DTD region auto-fix monitor..."
send_discord ":satellite: Monitor started. Watching for corrupt regions."

# === MAIN LOOP ===
while true; do
    maybe_backup_region

    FILE=$(grep -Eo "Incorrect region file header! .*\\.7rg" "$LOG_FILE" | awk '{print $NF}' | tail -n 1)

    if [[ -n "$FILE" && -f "$FILE" ]]; then
        log "[!] Corrupt region file detected: $FILE"
        send_discord ":warning: Corrupt region file detected:\n\`$FILE\`"
        last_action="corrupt_detected"

        log "[*] Stopping 7DTD server..."
        send_discord ":octagonal_sign: Stopping 7DTD server for cleanup..."
        $SDTDSERVER_CMD stop
        sleep 5
        kill_stuck_server_if_needed

        if [[ "$FILE" == "$REGION_DIR"* ]]; then
            backup_to_restore=$(ls -dt "$REGION_BACKUP_DIR"/region_* | sed -n "${CORRUPT_REPLACE_LOOKBACK_COUNT}p")
            if [[ -n "$backup_to_restore" && -f "$backup_to_restore/$(basename "$FILE")" ]]; then
                cp "$backup_to_restore/$(basename "$FILE")" "$FILE"
                log "[+] Restored $(basename "$FILE") from backup: $backup_to_restore"
                send_discord ":floppy_disk: Restored from backup:\n\`$FILE\`"
                last_action="restored"
            else
                log "[!] No backup found to restore from. Skipping."
                send_discord ":warning: No backup available for:\n\`$FILE\`"
                last_action="restore_skipped"
            fi
        else
            log "[x] Invalid file path. Skipping delete: $FILE"
            send_discord ":x: Invalid path, skipped:\n\`$FILE\`"
            last_action="invalid_path"
        fi

        log "[*] Restarting 7DTD server..."
        restart_server
        last_action="restarted"
    else
        case "$last_action" in
            idle)
                log "[.] Heartbeat: idle — no corrupt files detected."
                send_discord ":zzz: Heartbeat: no activity."
                ;;
            backup)
                log "[.] Heartbeat: backup completed."
                send_discord ":repeat: Heartbeat: backup routine successful."
                ;;
            corrupt_detected)
                log "[.] Heartbeat: corrupt region processed."
                ;;
            restored)
                log "[.] Heartbeat: file restored from backup."
                ;;
            restore_skipped)
                log "[.] Heartbeat: backup not found, skipped restoration."
                ;;
            invalid_path)
                log "[.] Heartbeat: invalid path encountered."
                ;;
            restarted)
                log "[.] Heartbeat: server restarted."
                ;;
            *)
                log "[.] Heartbeat: state unknown."
                ;;
        esac
        last_action="idle"
        sleep "$HEARTBEAT_INTERVAL"
    fi

done
