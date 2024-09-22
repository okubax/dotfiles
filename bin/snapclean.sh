#!/usr/bin/env bash
#
# clean-snap-sync-external.sh v1.0.1 (2021-07-09)
#
# Changes
# -------
# 2021-07-09:
#   - adjust logic to keep latest x, instead of delete oldest x
#   - make output cleaner (hide btrfs subvolume delete output)
#
# Inspired by FraYoshi's original
# See: https://github.com/wesbarnett/snap-sync/issues/16

# Change these for your environment
readonly snapshot_root=/run/media/ajibola/Snaps
readonly keep_latest=2

# Don't change these
readonly ansi_default="\e[39m"
readonly ansi_green="\e[32m"
readonly ansi_yellow="\e[33m"

echo -e "$ansi_green[DEBUG] Keeping the latest $keep_latest snapshots on $snapshot_root.$ansi_default"

# Use printf to get the filename without the path
find /etc/snapper/configs -mindepth 1 -maxdepth 1 -printf "%f\n" | while read config; do
    echo -e " $ansi_green[DEBUG] Checking $snapshot_root/$config$ansi_default"

    # Make sure the total number of snapshots is more than $keep_latest
    if [ $(find "$snapshot_root/$config" -mindepth 1 -maxdepth 1 -type d | wc -l) -gt $keep_latest ]; then
        # Find all snapshots for the current config, sort by snapshot number, and
        # get the oldest. Note that I would prefer to do this:
        #
        #   for snapshot in $(ls -1td /mnt/backup/root/*); do
        #
        # ... but parsing ls is apparently frowned upon. I will settle on using find
        # and sorting numerically, since snapshot numbers should be integers.
        #
        # See: http://mywiki.wooledge.org/ParsingLs
        #
        # Again, we rely on printf to get the snapshot number without the path,
        # then we sort the snapshot numbers in reverse numerical order, ie:
        #
        #   6601 (snapshot 1)
        #   6600 (snapshot 2)
        #   6599 (snapshot 3)
        #
        # Then we use `tail -n +` with $keep_latest + 1 to skip that many snap-
        # shots, as tail's `-n +` syntax starts at line 1.
        find "$snapshot_root/$config" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort -nr | tail -n +$(expr $keep_latest + 1) | while read snapnum; do
            echo -e "  $ansi_green[DEBUG] Found $snapshot_root/$config/$snapnum$ansi_default"

            # Make sure this is not the latest incremental backup. grep will return 
            # with a non-zero exit status if there is *no match*, so we continue to
            # delete matching snapshots if this command fails.
            if ! snapper -c "$config" list --columns number,description | grep -E "^$snapnum" | grep 'latest incremental backup' >/dev/null; then
                # Delete the snapshot itself
                echo -e "   $ansi_yellow[INFO] Deleting $snapshot_root/$config/$snapnum$ansi_default"
                btrfs subvolume delete "$snapshot_root/$config/$snapnum/snapshot" >/dev/null

                # Delete the snapper snapshot root (ie, where info.xml lives)
                # SC2115: Use "${var:?}" to ensure this never expands to / .
                rm -r "${snapshot_root:?}/$config/$snapnum"
            else
                echo -e "   $ansi_green[DEBUG] Not deleting $snapshot_root/$config/$snapnum because it is the latest incremental backup.$ansi_default"
            fi
        done
    else
        echo -e " $ansi_green[DEBUG] Number of snapshots in $snapshot_root/$config should be more than $keep_latest.$ansi_default"
    fi
done
