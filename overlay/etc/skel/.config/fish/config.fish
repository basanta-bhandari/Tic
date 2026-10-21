# Glyph's interactive Fish environment. System scripts intentionally use Bash.
if type -q nvim
    set -gx EDITOR nvim
else
    set -gx EDITOR nano
end
set -gx VISUAL $EDITOR
set -gx PAGER 'less -RF'
set -gx MANPAGER 'less -R'
set -gx DIALOGRC /etc/glyph/dialogrc
set -gx COLORTERM truecolor

set -g fish_greeting ''
set -g fish_color_normal ffb000
set -g fish_color_command ffd75f --bold
set -g fish_color_keyword ffd75f --bold
set -g fish_color_quote ffe29a
set -g fish_color_redirection ffffff
set -g fish_color_end ffb000
set -g fish_color_error ff5f5f --bold
set -g fish_color_param ffb000
set -g fish_color_comment 87875f
set -g fish_color_selection 000000 --background=ffb000
set -g fish_color_search_match 000000 --background=ffd75f
set -g fish_color_operator ffffff
set -g fish_color_escape ffffff
set -g fish_color_autosuggestion 6c603f
set -g fish_pager_color_progress ffb000 --bold
set -g fish_pager_color_prefix ffd75f --bold
set -g fish_pager_color_completion ffb000
set -g fish_pager_color_description 87875f

abbr -a -- ll 'eza -la --group-directories-first'
abbr -a -- la 'eza -a --group-directories-first'
abbr -a -- tree 'eza --tree'
abbr -a -- v nvim
abbr -a -- fm yazi
abbr -a -- gs 'git status'
abbr -a -- update 'sudo pacman -Syu'
abbr -a -- cleanup 'sudo pacman -Rns (pacman -Qtdq)'

if type -q zoxide
    zoxide init fish | source
end

function fish_prompt
    set_color ffd75f --bold
    printf '%s' (whoami)
    set_color 87875f
    printf '@%s ' (prompt_hostname)
    set_color ffb000 --bold
    printf '%s' (prompt_pwd)
    set_color ffd75f
    printf ' › '
    set_color normal
end

function fish_right_prompt
    set_color 6c603f
    date '+%H:%M'
    set_color normal
end

function yy
    set tmp (mktemp -t 'yazi-cwd.XXXXXX')
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# TTY1 is the desktop. Other TTYs and SSH sessions remain ordinary shells.
if status is-login; and not set -q GLYPH_NO_LAUNCH; and test (tty) = /dev/tty1
    glyph
end
