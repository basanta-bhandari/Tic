# Archiso's live root account uses zsh. Hand the interactive login to Fish so
# tty1 opens the Glyph workspace while retaining zsh as a recovery shell.
if [[ -x /usr/bin/fish && -z ${ZSH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/fish --login
fi
