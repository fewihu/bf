# execute shell in container
function desh
{
    container=$(docker ps | fzf --header-lines 1 | cut -d ' ' -f-1)
    if [ $# -eq 0 ]
    then
	shell="/bin/bash"
    else
	shell="$1"
    fi
    docker exec -it "$container" "$shell"
}

# find and execute command in container
function debin
{
    container=$(docker ps | fzf --header-lines 1 | cut -d ' ' -f-1)

    if [ $# -eq 0 ]
    then
	cmd=$(docker exec "$container" /bin/bash -c "compgen -c" | fzf)
	read -p "Enter arguments: " args
	docker exec "$container" "$cmd" "$args"
    else
	docker exec "$container" "$@"
    fi
}

# stop container
function dstp
{
    container=$(docker ps | fzf --header-lines 1 | cut -d ' ' -f-1)
    docker stop "$container"
}

# (force) remove container
function dcrm
{
    container=$(docker container ls -a | fzf --header-lines 1 | cut -d ' ' -f-1)
    docker container rm "$container" -f
}

function dhelp
{
    grep "function" ~/bf/docker/docker.sh -B2
}
