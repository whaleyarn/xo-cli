# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
# export LS_OPTIONS='--color=auto'
# eval "$(dircolors)"
# alias ls='ls $LS_OPTIONS'
# alias ll='ls $LS_OPTIONS -l'
# alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# Terminal color
GREEN='\033[1;32m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

function get-vm {
    xo-cli list-objects type=VM |\
    jq 'map({"name": .name_label, uuid})'
}

function pre-upgradevm {
    local uuid
    uuid=$(xo-cli list-objects type=VM name_label="${1}" |\
    jq -r '.[0].uuid')
    xo-cli vm.snapshot id="${uuid}"
}

# default revert to the last snapshot
function restore-upgradevm {
    local uuid
    uuid=$(xo-cli list-objects type=VM name_label="${1}" |\
    jq -r '.[0].uuid')
    local snap_uuid
    snap_uuid=$(xo-cli list-objects type=VM-snapshot '$snapshot_of'="$uuid" |\
    jq -r 'map({snapshot_time, uuid}) | sort_by(.snapshot_time) | .[-1].uuid')
    xo-cli vm.revert snapshot="${snap_uuid}"
}

# delete snapshot(s) of a VM that not start with regex '\w'
# Usage: post-upgradevm <VM_NAME> [-a]
# Options:
#   -a: Delete all snapshots (including those with names starting with non-word characters)
function post-upgradevm {
    local vm_name=""
    local delete_all_snapshots=false

    # Check if a VM_NAME is provided
    if [ $# -eq 0 ]; then
        echo "Error: VM_NAME is required." >&2
        return 1
    else
        vm_name="$1"
        shift
    fi

    # Parse command line options using getopts
    while getopts ":a" opt; do
        case $opt in
            a)
                delete_all_snapshots=true
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                return 1
                ;;
        esac
    done


    local uuid
    uuid=$(xo-cli list-objects type=VM name_label="${vm_name}" |\
    jq -r '.[0].uuid')
    local snap_uuid

    if [ "$delete_all_snapshots" = true ]; then
        snap_uuid=$(xo-cli list-objects type=VM-snapshot '$snapshot_of'="$uuid" |\
        jq -r 'map(select(.name_label | test("^\\w"))) | .[].uuid')
    else
        snap_uuid=$(xo-cli list-objects type=VM-snapshot '$snapshot_of'="$uuid" |\
        jq -r 'map({snapshot_time, uuid, name_label} )' |\
        jq -r 'map(select(.name_label | test("^\\w")))' |\
        jq -r 'sort_by(.snapshot_time) | .[-1].uuid')
    fi

    if [ -z "$snap_uuid" ]
    then
        echo -e "${GREEN}No snapshot need to delete${RESET}"
    else
        for uuid in $snap_uuid; do
            xo-cli vm.delete id="$uuid"
        done
    fi
}

# bash auto complete
if [[ -f "/etc/bash_completion.d/xo-cli-custom" ]];
then
    . "/etc/bash_completion.d/xo-cli-custom"
else
    echo 'ba'
fi

# load .bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
  for rc in $HOME/.bashrc.d/*; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi
