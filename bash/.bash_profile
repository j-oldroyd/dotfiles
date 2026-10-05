# Source - https://stackoverflow.com/questions/18393521/bashrc-not-loading-until-run-bash-command
# Posted by sjnarv
# Retrieved 11/4/2025, License - CC-BY-SA 4.0
if [ -f ~/.profile ]; then
    . ~/.profile
fi

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Added by `rbenv init` on Sat Apr 25 09:44:55 AM EDT 2026
eval "$(rbenv init - --no-rehash bash)"
