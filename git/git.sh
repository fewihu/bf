#! /bin/bash

# dependencies: git, fzf, delta (diff), xargs

# ===================================== #
# My personal git frontend              #
# ===================================== #

# === helpers ===

# check if in git root
test_cd()
{
    gitroot=$(git rev-parse --show-toplevel)
    act=$(pwd)
    if [ "$gitroot" != "$act" ]
    then
        echo "not in project root"
        echo "use cdgrt"
        return
    fi
}

# number of commits ahead or behind upstream
ahead_or_behind()
{
    git status -sb | grep -o -e 'ahead [0-9]*' -e 'behind [0-9]*'
}

# --- helpers end ---
# === push and pull ===

# prune stalled branches
function gprune()
{
    git fetch --prune origin "$@"
}

function gp()
{
    git push "$@"
}

function gpl()
{
    git pull "$@"
}

# push new local branch to origin
function gpus()
{
    if [ $# -eq 0 ]
    then
	git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)"
    else
	if [ "$1" == "-f" ]
	then
	    git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)" -f
	else
	    git push --set-upstream origin "$@"
	fi
    fi
}

# push specific reference to origin
function gpr()
{
    if [[ -z $1 ]]
    then
	echo "Provide a reference and (optiobnal) origin branch name"
	echo "Usage: gpref <local-ref> [<origin-name>]"
    fi

    upstream=$(git rev-parse --abbrev-ref HEAD)
    if [[ $# -eq 2 ]]
    then
	upstream=$2
    fi
    git push origin "$1":refs/heads/"$upstream" -f
}

# --- push and pull end ---
# === rebase ===

function gri ()
{
    if [ $# -ne 1 ]
    then
	printf "gri <n>"
	printf " * interactively rebase the last n commits"
	return
    fi
    git rebase -i HEAD~"$1" --autostash
}

# --- rebase end ---
# === log ===

# super fancy interactive git commit history
# CTRL-W copy chosen commit hash to clipboard
# CTRL-F preview git diff --name-only
# RETURN git show chosen commit
function gfh()
{
    git log --graph --color=always \
    --format="%C(cyan)%h %C(yellow)%s %C(auto)%d" "$@" |
    fzf -i -e +s \
    --reverse \
    --tiebreak=index \
    --no-multi \
    --ansi \
    --preview="echo {} |
        grep -o '[a-f0-9]\{4,64\}' |
        head -1 |
        xargs -I % sh -c 'git show --oneline --color=always % |
	delta'" \
	    --header "RET: show | C-w copy hash | C-f preview file names only" \
	    --bind "enter:execute( echo {} | grep -o '[a-f0-9]\{4,64\}' | head -1 | xargs -I % sh -c 'git show --oneline %')+accept" \
	    --bind "alt-w:execute(echo {} | grep -o '[a-f0-9]\{4,64\}' | head -1 | xclip -selection c)+accept" \
	    --bind "ctrl-f:preview(echo {} | grep -o '[a-f0-9]\{4,64\}' | head -1 | xargs git diff-tree --no-commit-id --name-only -r)"
}

function gl()
{
    case $1 in
	-s)
	    # short
	    shift
	    git_log_num 20 "$@"
	    ;;
	-l)
	    # long, l=<num>
	    shift
	    git_log_num 40 "$@"
	    ;;
	-l=*)
	    num=$(echo "$1" | grep -o [0-9]*)
	    shift
	    git_log_num "$num" "$@"
	    ;;
	-f)
	    # touched files
	    shift
	    git --no-pager log --reverse --name-only --oneline "$@"
	    ;;
	-g)
	    # graph
	    shift
	    git log --oneline --graph "$@"
	    ;;
	-*)
	    echo "Unknown option $1"
	    return 1
	    ;;
	*)
	    git_log_num 20 "$@"
	    ;;
    esac
}

git_log_num()
{
    branch=$(git rev-parse --abbrev-ref HEAD)
    upstream=$(git rev-parse --short origin/$branch 2> /dev/null)
    if [[ $? -ne 0 ]]
    then
	upstream=will_not_be_found
    fi

    default=$(git --no-pager branch --all | grep -E "^\* main|  main|* master|  master$" | grep -Eo "main|master")
    if [[ $? -ne 0 ]]
    then
       default=devel
    fi
    up_default=$(git rev-parse --short origin/$default)

    num="$1"
    shift
    git --no-pager log -n "$num" --pretty="%h :%G?:%<(20)%cn:END: %s" "$@" \
	| nl \
	| awk -v u="$upstream" '{ gsub(u,"\033[;1m"u"\033[;0m"); print }' \
	| awk -v d="$up_default" '{ gsub(d,"\033[36;1m"d"\033[;0m"); print }' \
	| awk '{ gsub(":N:","\033[33m"); print }' \
	| awk '{ gsub(":U:","\033[32m"); print }' \
	| awk '{ gsub(":G:","\033[32m"); print }' \
	| awk '{ gsub(":E:","\033[91m"); print }' \
	| awk '{ gsub(":X:","\033[92m"); print }' \
	| awk '{ gsub(":Y:","\033[92m"); print }' \
	| awk '{ gsub(":R:","\033[92m"); print }' \
	| awk '{ gsub(":B:","\033[31m"); print }' \
	| awk '{ gsub(":END:","\033[0m"); print }'
}

function gsw()
{
    if [[ $1 == '-np' ]]
    then
	shift
	git --no-pager show "$@"
    else
	git show "$@"
    fi
}

# --- log end ---
# === branches ===

# super fancy git checkout alias for remotes -> local
function gco()
{
    git branch --all | grep  remote | grep -v HEAD | cut -d '/' -f3- | \
    fzf -i -e +s \
	--reverse \
	--tiebreak=index \
	--no-multi \
	--ansi \
	--preview="echo {} | xargs git log --oneline --graph --decorate" \
	--header "select a branch and hit RET to check it out" \
	--bind enter:'execute(echo {} | xargs git checkout)+abort'
}

# switch to local branch
function gbl()
{
    git branch | grep -v "\*" | fzf | xargs git switch $@
}

# checkout main or master
function gmain()
{
    branch=$(git --no-pager branch --all | grep -E "^\* main|  main|* master|  master$" | grep -Eo "main|master")
    if [[ -n $branch ]]
    then
	git checkout "$branch" "$@"
    else
	echo "could not find main or master, trying devel"
	git checkout devel "$@"
    fi
}


# diff, show staging area by default
function giff()
{
    if [[ $1 == '-s' ]]
    then
	shift
	git diff --cached "$@"
	return
    elif [[ $1 == "-n" ]]
    then
	shift
	git diff --name-only
	return
    fi
    git diff "$@"
}

# new branch
function gnb()
{
    if [ $# -lt 1 ]
    then
	echo "gnb <branch>"
	echo " * create new local branch <branch>"
	return
    fi
    git checkout -b "$@"
}

# git branch
function gb()
{
    if [ $# -eq 0  ]
    then
	# if no args were supplied, give an overview
	git branch --all
	return
    else
	# if args were supplied use gb as alias
	git branch "$@"
    fi
}

# --- branches end ---
# === tag ===

# copy tag to clipboard or check it out
# RETURN checkout
# CTRL-W copy to clipboard
function glt()
{
    git tag --sort=taggerdate | tac | \
    fzf -i -e +s \
	--reverse \
	--tiebreak=index \
	--no-multi \
	--ansi \
	--preview="echo {} | xargs git show --quiet" \
	--header "RET to check it out" \
	--bind "enter:execute( echo {} | xargs -I % sh -c 'git checkout %')+accept" \
	--bind "ctrl-w:execute(echo {} | xclip -selection c)+accept"
}

# --- tag end ---
# === commit ===

# discard changes in working directory patchwise
function gd()
{
    if [ "$1" == "-s" ]
    then
	shift
	git reset HEAD "$@" -p
	return
    elif [ "$1" == "-a" ]
    then
	 shift
	 git reset HEAD
	 return
    fi
    git checkout -p -- "$@"
}

# commit
function gc()
{
    if [[ "$1" == "-nv" ]]
    then
	shift
	git commit -s --no-verify "$@"
    else
	git commit -s "$@"
    fi
}

# discard last commit, but keep staging area
function guc
{
    git reset @~
}

ga_single()
{
    allStatus=$(git status -s "$@" | cut -b4-)
    for s in $allStatus
    do
	status=$(git status -s "$s"| cut -b-2)
	if [ "$status" == "??" ]
	then
	    if [[ $s =~ /$ ]]
	    then
		ga_new_dir "$s"
		return
	    fi
	    git add "$s"
	    echo "Added new file $s entirely"
	    return
	fi
	git add -p "$@"
    done
}

ga_new_dir()
{
    for file in $(find "$1" -type f)
    do
	echo "Add file $file from new directory $1? (y/n)"
	read -n1  input
	echo ""
	if [ "$input" == "y" ]
	then
	    git add "$file"
	fi
    done
}

# add
function ga()
{
    if [ $# -eq 0 ]
    then
	for var in $(echo *)
	do
	    ga_single "$var"
	done
    else
	for var in "$@"
	do
	    ga_single "$var"
	done
    fi

}

# amend commit
function gam()
{
    if [[ "$1" == "-nv" ]]
    then
	shift
	git commit --amend --no-verify "$@"
    else
	git commit --amend "$@"
    fi
}

# amend without edit
function gane()
{
    if [[ "$1" == "-nv" ]]
    then
	shift
	git commit --amend --no-edit --no-verify "$@"
    else
	git commit --amend --no-edit "$@"
    fi
}

# --- commit end ---
# === status ===

# git status
function gss()
{
    git status "$@"
}

# git short status with ahead or behind info relativ to remote
function gs()
{
    ahead_or_behind
    if [[ $1 == "-i" ]]
    then
	shift
	git status -s --ignored "$@"
    else
	git status -s "$@"
    fi
}

# --- status end ---
# === others ===

# change directory to git root if pwd is in git repo
function cdgrt()
{
    target=$(git rev-parse --show-toplevel)
    if [ $? -eq 0 ]; then
	echo "switching to git root: $target"
	cd "$target"
    fi
}

# just git
function g()
{
    git "$@"
}

# show all commits that touched file given as parameter
function gfileh()
{
    if [ -z "$1" ]
    then
	echo "Usage: gfullHist <file>"
	return;
    fi
    git --no-pager log --pretty="%H: %s (%cn)" --follow "$1"
}

# files touched by last commit
function gtch()
{
    git show --pretty="" --name-only "$@"
}

# show top level README.md if there is one
function grm()
{
    target=$(git rev-parse --show-toplevel);

    if [ -f "$target/README.md" ]
    then
	echo "found README.md at $target"
	glow "$target/README.md"
    else
	echo "No README.md present, switching back"
    fi
}


# --- others end ---

function ghelp()
{
    if [ $# -eq 1 ]
    then
	grep "function" -B1 ~/bf/git/git.sh | grep -E -A2 "# (.)*$1"
    else
	grep "function" -B1 ~/bf/git/git.sh
    fi
}
