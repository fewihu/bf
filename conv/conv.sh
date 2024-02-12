function psig()
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
