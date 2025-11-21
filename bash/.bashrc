# emacs --daemon runs on startup, so let's alias emacs to emacsclient
alias emacs="emacsclient -c -n"

# ssh-agent should be taken care of by systemctl now
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
ssh-add ~/.ssh/github

fastfetch
