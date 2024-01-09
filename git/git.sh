#! /bin/bash

# dependencies: git, fzf, delta (diff), xargs

# ===================================== #
# My personal git frontend              #
# ===================================== #

# === helper functions ===

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
# --- helper functions end ---

# === push and pull ===
# prune stalled branches
function gprune()
{
    git fetch --prune origin
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
	git push --set-upstream origin "$@"
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
    git rebase -i HEAD~"$1"
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
	    --bind "ctrl-w:execute(echo {} | grep -o '[a-f0-9]\{4,64\}' | head -1 | xclip -sel clip)+accept" \
	    --bind "ctrl-f:preview(echo {} | grep -o '[a-f0-9]\{4,64\}' | head -1 | xargs git diff-tree --no-commit-id --name-only -r)"
}

# print changes that came with given commit
function gchg()
{
    if git cat-file commit "$1"; then
        git diff $1~ "$1"
    else   	
        echo "$1" does not exist
    fi
}

function gl()
{
    case $1 in
	-s)
	    git_log_num 20
	    ;;
	-l)
	    git_log_num 40
	    ;;
	-f)
	    git --no-pager log --format='---%n%s%n%b'
	    ;;
	-g)
	    git log --oneline --graph
	    ;;
	-*|--*)
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
    git --no-pager log --oneline | head -"$1" | nl
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
    git branch | grep -v "\*" | fzf | xargs git switch
}

# checkout main or master
function gmain()
{
    git --no-pager branch --all | grep -E "[* |  ]master$" > /dev/null
    if [ $? -eq 0 ]
    then
	git checkout master
    fi

    git --no-pager branch --all | grep -E "[* |  ]main$" > /dev/null
    if [ $? -eq 0 ]
    then
	git checkout main
    fi
}


# diff
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
    git checkout -b "$@"
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
	--preview="echo {} | xargs git log --oneline --graph --decorate" \
	--header "select a tag and hit RET to check it out" \
	--bind "ctrl-s:preview(echo {} | xargs -I % sh -c 'git show --quiet %')" \
	--bind "enter:execute( echo {} | xargs -I % sh -c 'git checkout %')+accept" \
	--bind "ctrl-w:execute(echo {} | clip.exe)+accept"    
} 
# --- tag ---

# === commit ===
# commit
function gc()
{
    git commit "$@"
}

# add and commit
function gac()
{
    git add "$@"
    git commit
}

# add
function ga()
{
    git add "$@"
}

# interactive patchwise git add
function gadd(){
    while :
    do
	FILE=$(git status -s | grep -e "^M  " -v | grep -v "^ ?" | grep -v "^ D" | grep -v "^ A"  | grep -v "^A "  | fzf )
	if [ -z  "$FILE" ]
	then
	    break
	fi

	echo "$FILE" | grep "??"
	if [ $? -ne 0 ]
	then
	    git add -p "$(echo "$FILE" | cut -b4-)"
	else
	    git add "$(echo "$FILE" | cut -b4- )"
	fi
    done
}

# amend commit
function gamend()
{
    git commit --amend
}

# amend without edit
function gane()
{
    git commit --amend --no-edit
}
# --- commit end ---

# === status ===
# git status
function gst()
{
    git status
}

# git short status with ahead or behind info relativ to remote
function gs()
{
    ahead_or_behind
    git status -s
}
# --- status end ---

# === others ===
# change directory to git root if pwd is in git repo
function cdgrt()
{
    target=$(git rev-parse --show-toplevel)
    if [ $? -eq 0 ]; then
	echo "switching to git root: $target"
	cd $target
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
function gtouched()
{
    git show --pretty="" --name-only   
}
# --- others end ---
