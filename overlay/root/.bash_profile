if [[ -x /usr/bin/kage && -z ${BASH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/kage --login
elif [[ -x /usr/bin/fish && -z ${BASH_EXECUTION_STRING:-} ]]; then
    exec /usr/bin/fish --login
fi
