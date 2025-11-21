# These variables must be set for emacs --daemon to run properly
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

export MANPATH=/usr/local/texlive/2025/texmf-dist/doc/man:$MANPATH
export INFOPATH=/usr/local/texlive/2025/texmf-dist/doc/info:$INFOPATH
export PATH=/usr/local/texlive/2025/bin/x86_64-linux:$PATH

export VISUAL='emacsclient -c -n -a ""'
export EDITOR="$VISUAL"
