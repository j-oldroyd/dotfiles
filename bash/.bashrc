# I want Emacs to run on startup. emacsclient will start a new daemon if
# necessary. Unfortunately, I can't get systemctl to work on Arch at the
# moment, so this is my fallback.
# emacs --daemon
# Now it seems to be working...

# ssh-agent should be taken care of by systemctl now
#eval "$(ssh-agent -s)"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
ssh-add ~/.ssh/github

fastfetch
