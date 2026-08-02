#!/usr/bin/env bash
# undo-btrfs-rollback.sh — fully revert the Btrfs snapshot rollback setup created
# by install-btrfs-rollback.sh. Restores your original fstab and removes every
# file/subvol the setup added.
#
#   Run: sudo bash ~/undo-btrfs-rollback.sh
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Please run with sudo."; exit 1; }

POOL="/mnt/btr_pool"
BOOT="/boot"
ENTRIES="$BOOT/loader/entries"
HOOKDIR="/etc/pacman.d/hooks"

echo "==> Reverting Btrfs snapshot rollback setup"

# 1. Restore fstab from the EARLIEST backup (the pristine pre-setup original).
BK="$(ls -1d /root/btrfs-rollback-backup-* 2>/dev/null | sort | head -1)"
if [[ -n "${BK:-}" && -f "$BK/fstab" ]]; then
    cp -a /etc/fstab "/etc/fstab.pre-undo.$(date +%Y%m%d_%H%M%S)"
    cp -a "$BK/fstab" /etc/fstab
    echo "    restored /etc/fstab from $BK"
else
    echo "    WARN: no backup fstab found. Leaving /etc/fstab as-is."
    echo "          It only had subvolid pins removed (harmless). To fully restore"
    echo "          the originals, re-add subvolid=256 to the / line and"
    echo "          subvolid=6659 to the /home line by hand."
fi

# 2. Remove the pacman hook.
if rm -f "$HOOKDIR/00-btrfs-pre-snapshot.hook"; then echo "    removed pacman hook"; fi

# 3. Remove the boot entry + rollback kernel copies.
rm -f "$ENTRIES/arch-rollback.conf" && echo "    removed arch-rollback.conf"
rm -f "$BOOT/vmlinuz-linux-rollback" "$BOOT/initramfs-linux-rollback.img" \
    && echo "    removed rollback kernel copies"

# 4. Remove the helper scripts.
rm -f /usr/local/bin/btrfs-pre-snapshot /usr/local/bin/btrfs-rollback \
    && echo "    removed /usr/local/bin/{btrfs-pre-snapshot,btrfs-rollback}"

# 5. Delete the @rollback subvolume (safe unless you are booted on it).
if btrfs subvolume show "$POOL/@rollback" >/dev/null 2>&1; then
    booted="$(findmnt -no FSROOT / 2>/dev/null | sed 's#^/##')"
    if [[ "$booted" == "@rollback" ]]; then
        echo "    WARN: you are BOOTED on @rollback; not deleting it."
        echo "          Reboot into the default entry (subvol=@), then re-run this script."
    else
        btrfs subvolume delete "$POOL/@rollback" && echo "    deleted @rollback subvolume"
    fi
fi

echo
echo "==> Done. Notes:"
echo "  - @broken_* subvolumes from 'promote' are left untouched. List any with:"
echo "      sudo btrfs subvolume list $POOL | grep @broken"
echo "  - Backups in /root/btrfs-rollback-backup-* are kept for safety; delete when happy."
echo "  - Reboot so systemd re-reads the restored fstab."
