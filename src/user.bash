#!/user/bin/env bash

subcommand_fail() {
    die "$1 Please specify a valid subcommand."
}

PATH_TO_CHECK=""

set_path_to_check() {
    local repo_path="$PREFIX/$1";
    set_git "$repo_path"
    PATH_TO_CHECK=""
    if [[ -n "$INNER_GIT_DIR" ]]; then
        if [[ -d "$repo_path" ]]; then
            PATH_TO_CHECK="$1"
        elif [[ -f "$repo_path.gpg" ]]; then
            PATH_TO_CHECK=$( dirname "$repo_path" )
        fi
    fi
}


cmd_user_exists() {
    set_git "$PREFIX/"
    if [[ -z "$INNER_GIT_DIR" ]]; then
        die "The git repository is not initialized."
    fi
    if ! [[ -d "$PREFIX/.users" ]]; then
        die "User management not initialized."
    fi

    while [[ $# -gt 0 ]]; do
        local user="$1"
        if ! [[ -f "$PREFIX/.users/$user" ]]; then
            exit 1
        fi
        shift
    done
    exit 0
}

cmd_user_add() {
    [[ $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND add gpg-id"
    gpg_id=$1
    user_directory="$PREFIX/.users"
    if ! [[ -e $user_directory ]]; then
        mkdir "$user_directory"
    elif ! [[ -d "$user_directory" ]]; then
        die "Error: $user_directory exists but is not a directory."
    fi
    user_key_file="$user_directory/$gpg_id"
    if [[ -e  "$user_key_file" ]]; then
        die "Key for user $gpg_id already present."
    fi
    $GPG "${GPG_OPTS[@]}" --local-user "$gpg_id" --output "$user_key_file" --armor --export
    set_git "$user_key_file"
    git_add_file "$user_key_file" "Add user '$gpg_id' to repository."
}


cmd_user_list() {
    [[ $# -ne 0 ]] && die "Usage: $PROGRAM $COMMAND list"
    ls "$PREFIX/.users"
}

cmd_user_import() {
    [[ $# -lt 1 ]] && die "Usage: $PROGRAM $COMMAND gpg-id..."
    users_to_trust=()
    user_directory="$PREFIX/.users"

    while [[ $# -gt 0 ]]; do
        if [[ $1 == "--all" ]]; then
            shopt -s nullglob
            users_to_trust=( "$user_directory"/* )
            shopt -u nullglob
            break
        else
            if [[ ! -f "$user_directory/$1" ]]; then
                die "Unkown user '$1'."
            fi
            USERS+=( "$user_directory/$1" )
            break
        fi
    done
    for user_file in "${users_to_trust[@]}"; do
        $GPG $PASSWORD_STORE_GPG_OPTS --import $user_file
    done
}

cmd_user_privy( ) {
    [[ $# -lt 2 ]] && die "Usage: $PROGRAM $COMMAND privy gpg-id secret-path"
    checked_user="$1"
    shift

    if ! [[ -f "$PREFIX/.users/$checked_user" ]]; then
        exit 1
    fi



    while [[ $# -gt 0 ]]; do
        set_path_to_check "$1"
        if [[ -z "$PATH_TO_CHECK" ]]; then
            exit 1
        fi
        set_gpg_recipients "$PREFIX/$PATH_TO_CHECK"
        is_privy=0
        for privy_user in "${GPG_RECIPIENTS[@]}"; do

            if [[ "$checked_user" == "$privy_user" ]]; then
                is_privy=1
                break
            fi
        done
        shift
        if [[ "$is_privy" -eq 0 ]]; then
            exit 1
        fi
    done

    exit 0
}

cmd_user_join() {
    [[ $# -ne 2 ]] && die "Usage: $PROGRAM $COMMAND user join gpg-id repo-url"
    local user_to_join="$1"
    local remote_to_join="$2"
    if [[ -d "$PREFIX" ]]; then
        set_git "$PREFIX"
        [[ -z "$INNER_GIT_DIR" ]] && \
            die "Git path '$PREFIX' is present" \
                " but does not seem to be a git directory."
        local current_remote="";
        current_remote=$(git -C "$INNER_GIT_DIR" remote get-url origin)
        [[ "$current_remote" != "$remote_to_join" ]] && \
            die "Git is already set to origin '$current_remote'."
    else
        git clone "$remote_to_join" "$PREFIX"
    fi
    cmd_user_add "$user_to_join"
}



[[ $# -lt 1 ]] && subcommand_fail "No subcommand given."

case "$1" in
    add) shift;         cmd_user_add "$@" ;;
    exists) shift;      cmd_user_exists "$@" ;;
    list|ls) shift;     cmd_user_list "$@" ;;
    import) shift;      cmd_user_import "$@" ;;
    privy) shift;       cmd_user_privy "$@" ;;
    join) shift;        cmd_user_join "$@" ;;
    *)              subcommand_fail "Unknown subcommand '$1'." ;;
esac
exit 0