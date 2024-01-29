# emacs (and editor) related alias and functions

export EDITOR="emacsclient -c"

# -- daemon 
alias eds="emacs --daemon"
alias edk='emacsclient --eval "(kill-emacs)"'

function edr()
{
    emacsclient --eval "(kill-emacs)"
    emacs --daemon
}

# -- client
# lucid
alias em="emacsclient -c"
alias e="emacsclient -c -F \"'(fullscreen . maximized)\""
# nox
alias et="emacsclient"
# if everything is falling apart
alias eq="emacs -q"
