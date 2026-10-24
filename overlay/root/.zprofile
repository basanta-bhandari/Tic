# Archiso's live root account uses zsh. Hand the interactive login to Fish so
# tty1 opens Zenith through Kage while retaining zsh as a recovery shell.
if [[ -x /usr/bin/kage && -z ${ZSH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/kage --login
elif [[ -x /usr/bin/fish && -z ${ZSH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/fish --login
fi
