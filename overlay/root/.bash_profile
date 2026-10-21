if [[ -x /usr/bin/fish && -z ${BASH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/fish --login
fi
