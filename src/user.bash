#!/user/bin/env bash

subcommand_fail() {
    die "$1 Please speciffy one of the following: add, list"
}


cmd_add_user() {
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


cmd_list_user() {
    [[ $# -ne 0 ]] && die "Usage: $PROGRAM $COMMAND list"
    ls "$PREFIX/.users"
}

cmd_import_user() {
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

[[ $# -lt 1 ]] && subcommand_fail "No subcommand given."

case "$1" in
    add) shift;     cmd_add_user "$@" ;;
    list|ls) shift; cmd_list_user "$@" ;;
    import) shift;   cmd_import_user "$@" ;;
    *)              subcommand_fail "Unknown subcommand '$1'." ;;
esac
exit 0