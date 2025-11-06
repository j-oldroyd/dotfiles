# I want Emacs to run on startup. emacsclient will start a new daemon if
# necessary. Unfortunately, I can't get systemctl to work on Arch at the
# moment, so this is my fallback.
# emacs --daemon
# Now it seems to be working...

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github

fastfetch
