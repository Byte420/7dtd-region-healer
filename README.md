# 💀️🛠️ 7DTD Region Healer

A self-healing region file monitor for **7 Days to Die** dedicated servers.\
Detects corrupt `.7rg` region files, restores them from backup, restarts the server, and alerts you via **Discord**.

> Built with survival in mind — for servers that can't afford downtime.

---

## 🔧 Features

- 🔁 **Live Monitoring**: Watches your server logs for corrupt region file exceptions.
- 💾 **Automated Region Backups**: Saves `.7rg` files on an interval with configurable retention.
- 🧠 **Smart Restore Logic**: Replaces corrupt regions from the most recent valid backup.
- 🧹 **Process Watchdog**: Detects stuck server processes and kills them (with a backup first!).
- 📡 **Heartbeat Pings**: Discord and log messages every interval, with action-specific messages.
- ♻️ **Auto-Restart with Retries**: Tries multiple times to bring your server back up.
- 🛠️ **Fully Configurable**: Adjust intervals, paths, backups, and lookback depth directly in the script.

---

## 🚀 Installation

1. Clone or download the repo:

   ```bash
   git clone https://github.com/YourUsername/7DTD-Region-Healer.git
   cd 7DTD-Region-Healer
   ```

2. Edit the script to match your server paths and webhook URL:

   ```bash
   nano autofix_region_healer.sh
   ```

3. Make it executable:

   ```bash
   chmod +x autofix_region_healer.sh
   ```

4. Run it:

   ```bash
   ./autofix_region_healer.sh
   ```

Want it to run in the background? Use `tmux` or a systemd service.

---

## 🧹 Configuration

All configuration options are inside the script:

| Option                           | Description                                   | Default            |
| -------------------------------- | --------------------------------------------- | ------------------ |
| `REGION_DIR`                     | Path to your world’s Region directory         | Required           |
| `REGION_BACKUP_DIR`              | Where to store backups                        | `~/region_backups` |
| `REGION_BACKUP_INTERVAL_MINUTES` | How often to make backups                     | `60`               |
| `REGION_BACKUP_RETENTION_COUNT`  | How many backups to keep                      | `24`               |
| `CORRUPT_REPLACE_LOOKBACK_COUNT` | How far back to look for last known good file | `1`                |
| `HEARTBEAT_INTERVAL`             | Log + Discord heartbeat interval              | `10 seconds`       |
| `MAX_RESTART_ATTEMPTS`           | How many times to retry server restarts       | `5`                |
| `PROCESS_KILL_TIMEOUT`           | Wait before force-killing stuck server        | `60 seconds`       |
| `WEBHOOK_URL`                    | Your Discord webhook URL                      | Required           |

---

## 🧪 Status Messaging

Every major action sends a message:

- Corrupt file found ✅
- Server stopped / stuck / killed 😵
- File restored from backup 💾
- Server restarted 🔄
- Heartbeats when idle or after backups 🧘

---

## 📸 Example Output

In `autofix.log` and Discord:

```
[+] Starting 7DTD region auto-fix monitor...
[!] Corrupt region file detected: r.3.-3.7rg
[*] Stopping 7DTD server...
[*] Restored r.3.-3.7rg from backup: region_2025-07-07_14-12-33
[*] Restarting 7DTD server...
[+] Server successfully started.
```

---

## 🧠 Why This Exists

This tool was built to support the **MG7D.com** community servers, where uptime and world persistence are critical.\
Created and maintained by [248Tech.com](https://248tech.com) — helping gamers and devs automate what sucks.

---

## ✨ Credits

- Developed by [**Joe W. A.K.A. "Frosty"**](https://github.com/Byte420)
  - Founder of [MG7D.com](https://MG7D.com) & [248Tech.com](https://248Tech.com)
  - Mustang enthusiast, wrench-slinger, and full-stack dev.

---

## 📜 License

MIT — use it, share it, tweak it. But please don't nuke your server and blame us 😉

---

> Want help customizing or integrating into your host environment?\
> Reach out at [248Tech.com](https://248tech.com) for professional support, automation solutions, and server-side scripting.

