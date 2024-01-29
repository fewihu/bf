alias pls="pass list"
alias padd="pass add"
alias pcp="pass show -c"
alias prm="pass rm"

function pnew()
{
    if [ -z "$1" ]
    then
	echo "Usage $0 <alias>"
	read -p "Provide a alias for the new key" alias
    else
	alias="$1"
    fi
    pass generate -c "$alias" 128
}

function puse()
{
    key=$(pass ls | tail -n +2 | grep -Eo "([[:alnum:]]+(-)?)+"  | fzf)
    pass show -c "$key"
}
