#!/user/bin/env bash


[[ $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND git-repo"

GIT_REPO=$1

if [[ -e "$PREFIX" ]]; then
    die "The internal passwordstore is already initalized."
fi

git clone "$GIT_REPO" "$PREFIX"
