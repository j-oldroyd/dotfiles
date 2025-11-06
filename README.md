# dotfiles

These are my dotfiles for an Arch Linux/WSL configuration.

## Emacs

This configuration uses `systemd` to run an Emacs daemon on start,
using the code suggested
[here](https://emacsredux.com/blog/2020/07/16/running-emacs-with-systemd/
"Emacs Redux systemd page").  However, this causes a problem with
using `ssh-agent` in `.bashrc`, as that's run after the daemon above
starts.  If I run `emacsclient`, it will then be unaware of the
ssh-agent.  To get around this, I follow the instructions
[here](http://yitang.uk/2025/01/26/setup-sshagent-systemd-service-for-emacs/
"Yi Tang (Data Science and Emacs) page on Emacs, SSH and Systemd").
