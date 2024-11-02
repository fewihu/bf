function psig
{
    p=$(ps -ax -ho pid,command | fzf --header="    pid|cmd" | awk '/[:digit]+/ {print $1}')
    s=$(printf  "SIGINT\nSIGSTOP\nSIGKILL\n" | fzf)
    echo "sending $s to $p"
    kill -s "$s" "$p"
    
    echo "waiting for $p to die"
    sleep 3

    ps --pid $p > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
	echo "$p still lives"
    else
	echo "$p id dead"
    fi 
}

alias mv="mv -i"

# clear
alias c="clear"

# cd shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias l-="ls -l"

# bash-git-prompt
if [ -f "$HOME/tools/bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_THEME="Solarized_Ubuntu"
    GIT_PROMPT_ONLY_IN_REPO=0
    source "$HOME/tools/bash-git-prompt/gitprompt.sh"
fi

alias notes="emacsclient -c -F \"'(fullscreen . maximized)\" ~/notes/notes.org"

# update system
function update
{
   sudo snap refresh
   sudo apt update -y
   sudo apt upgrade -y
}
