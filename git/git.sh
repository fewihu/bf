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
	    git_log_num 20
	    ;;
	-l)
	    if [ -z $2 ]
	    then
		let num=40
	    else
		num=$2
	    fi
	    git_log_num "$num"
	    ;;
	-f)
	    git --no-pager log --reverse --name-only --oneline
	    ;;
	-g)
	    git log --oneline --graph
	    ;;
	-*)
	    echo "Unknown option $1"
	    return 1
	    ;;
	*)
	    git_log_num 20
	    ;;
    esac
}

git_log_num()
{
    git --no-pager log -n "$1" --pretty="%h :%G?:%<(20)%cn:END: %s" \
	| nl \
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
    git show "$@"
}

# --- log end ---
# === branches ===

# super fancy git checkout alias for remotes -> local
function gchck()
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
function gbloc()
{
    git branch | grep -v "\*" | fzf | xargs git switch $@
}

# checkout main or master
function gmain()
{
    branch=$(git --no-pager branch --all | grep -E "^\* main|  main|* master|  master$" | grep -Eo "main|master")
    if [[ -n $branch ]]
    then
	git checkout "$branch"
    else
	echo "could not find main or master"
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
function gdisc()
{
    if [ "$1" == "-s" ]
    then
	shift
	git reset HEAD "$@" -p
	return
    fi
    git checkout -p -- "$@"
}

# commit
function gc()
{
    git commit -s "$@"
}

# add and commit
function gac()
{
    git add "$@"
    git commit
}

# discard last commit, but keep staging area
function guc
{
    git reset @~
}

# add
function ga()
{
    status=$(git status -s "$@"| cut -b-2)
    if [ "$status" == "??" ]
    then
	git add "$@"
	return 0
    fi
    git add -p "$@"
}

# amend commit
function gamend()
{
    git commit --amend "$@"
}

# amend without edit
function gane()
{
    git commit --amend --no-edit "$@"
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
    git status -s "$@"
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
    git --no-pager log --pretty="%h" --follow "$1" | xargs git --no-pager show
}

# files touched by last commit
function gtch()
{
    git show --pretty="" --name-only   
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
