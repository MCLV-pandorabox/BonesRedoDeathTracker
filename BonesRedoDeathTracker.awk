#!/usr/bin/awk -f
#
# BonesRedoDeathTracker.awk
# Author: MCLV-pandorabox
# License: MIT No Attribution (MIT-0)
#
# Parses debug.txt from a Minetest server running the
# Bones Redo mod by OgelGames.
# Tracks bones placement, movement, and removal, outputting a summary of bones locations by player.
# Optionally: with -v taker=1 prints only the bones taken overview.
#
# Usage:
#   awk -f BonesRedoDeathTracker.awk /path/to/debug.txt
#   awk -v taker=1 -f BonesRedoDeathTracker.awk /path/to/debug.txt
#

function clean_loc(str) {
    gsub(/\./, "", str)
    gsub(/^\(|\)$/, "", str)
    return str
}

BEGIN {
    show_taker = (taker == 1)
}

# Track bones when placed
/Bones placed/ {
    owner = $4
    loc = clean_loc($7)
    bones_at[loc] = owner
    death[owner "|" loc] = 1
}

# Remove bones record and track taker/owner on item pickup
/takes items/ {
    taker = $4
    loc = clean_loc($10)
    owner = bones_at[loc]
    if (owner && taker != owner) {
        bones_taken[taker "|" owner]++
    }
    delete bones_at[loc]
    for (key in death) {
        split(key, arr, "|")
        if (arr[2] == loc) delete death[key]
    }
}

# Remove bones record when bones are removed by wrench
/uses wrench:wrench/ {
    match($0, /under=([^) ]+)/, m)
    if (m[1]) {
        loc = clean_loc(m[1])
        delete bones_at[loc]
        for (key in death) {
            split(key, arr, "|")
            if (arr[2] == loc) delete death[key]
        }
    }
}

# Update bones location when moved
/Bones of .* moved from/ {
    match($0, /Bones of ([^ ]+) moved from \(([^)]+)\) to \(([^)]+)\)/, m)
    if (m[1] && m[2] && m[3]) {
        user = m[1]
        oldloc = clean_loc(m[2])
        newloc = clean_loc(m[3])
        bones_at[newloc] = user
        delete bones_at[oldloc]
        delete death[user "|" oldloc]
        death[user "|" newloc] = 1
    }
}

END {
    if (show_taker) {
        # Only show bones taken overview
        print "Bones taken overview:\nTaker\tOwner\tCount"
        for (key in bones_taken) {
            split(key, arr, "|")
            print arr[1] "\t" arr[2] "\t" bones_taken[key]
        }
        exit
    }

    # By default, show only remaining bones locations
    print "Remaining bones locations:\nPlayer\t\tLocation"
    for (key in death) {
        split(key, arr, "|")
        print arr[1] "\t\t" arr[2]
    }
}
