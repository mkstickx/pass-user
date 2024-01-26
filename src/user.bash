#!/user/bin/env bash
set -eo pipefail

USER_EXTENSION_VERSION="0.2.1"
USER_FOLDER=".users"
subcommand_fail() {
    die "$1 Please specify a valid subcommand." \
        "Run '$PROGRAM $COMMAND help' for more information."
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

USED_GPG_ID_FILE=""

set_used_gpg_id_file() {
    local recipient_source_dir="$1"
    while [[ "$recipient_source_dir" =~ "$PREFIX/"*  ]]; do
        if [[ -f "$recipient_source_dir/.gpg-id" ]]; then
            break;
        fi
        recipient_source_dir=$(dirname "$target")
    done
    local found_file="$recipient_source_dir/.gpg-id"
    if [[ "$found_file" =~ "$PREFIX/"*  ]] \
        && [[ -f "$recipient_source_dir/.gpg-id" ]]; then
        USED_GPG_ID_FILE="$found_file"
    else
        USED_GPG_ID_FILE="$PREFIX/.gpg-id"
    fi
}

add_recipient() {
    local dir="$1"
    local user="$2"

    local target="$PREFIX/$dir"
    set_used_gpg_id_file "$target"
    local gpg_id_file_to_edit="$target/.gpg-id"
    if ! [[ -f "$USED_GPG_ID_FILE" ]]; then
        die "Error: password store is not initialized. Try \"pass init\"."
    fi
    while read -r present_user; do
        if [[ "$present_user" == "$user" ]]; then
            echo "User '$user' already of dir '$dir'." 1>&2
            return 0
        fi
    done < "$USED_GPG_ID_FILE"


    if ! [[ -f "$gpg_id_file_to_edit" ]]; then
        cp "$USED_GPG_ID_FILE" "$gpg_id_file_to_edit"
    fi
    echo "$user" >> "$gpg_id_file_to_edit"
    reencrypt_path "$target"
    set_git "$target"
    git_add_file "$target" "Add '$user' to folder '$dir'."
}

cmd_user_init() {
    if [[ -e "$PREFIX" ]]; then
        die "Pass already initialized."
    fi
    local user_to_join="$1"
    local remote_to_join="$2"
    set_git "$PREFIX/"
    if [[ -n "$INNER_GIT_DIR" ]]; then
        die "The git repository is already initialized."
    fi
    git clone "$remote_to_join" "$PREFIX"
    if [[ -e "$PREFIX/.gpg-id" ]]; then
        rm -rf "$PREFIX"
        die "Pass already initialized in cloned in '$remote_to_join'."
    fi
    cmd_init "$user_to_join"
    cmd_git init
    cmd_user_add "$user_to_join"
    cmd_git push
}

cmd_user_version() {
    echo "$USER_EXTENSION_VERSION"
    exit 0
}

cmd_user_exists() {
    set_git "$PREFIX/"
    if [[ -z "$INNER_GIT_DIR" ]]; then
        die "The git repository is not initialized."
    fi
    if ! [[ -d "$PREFIX/$USER_FOLDER" ]]; then
        die "User management not initialized."
    fi


    while [[ $# -gt 0 ]]; do
        local user="$1"
        if ! [[ -f "$PREFIX/$USER_FOLDER/$user" ]]; then
            die "Unknown user '$user'."
        fi
        shift
    done
    exit 0
}

cmd_user_add() {
    [[ $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND add gpg-id"
    gpg_id=$1
    user_directory="$PREFIX/$USER_FOLDER"
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
    ls "$PREFIX/$USER_FOLDER"
}

cmd_user_import() {
    [[ $# -lt 1 ]] && die "Usage: $PROGRAM $COMMAND gpg-id..."
    users_to_import=()
    user_directory="$PREFIX/$USER_FOLDER"

    while [[ $# -gt 0 ]]; do
        if [[ $1 == "--all" ]] || [[ $1 == "-a" ]]; then
            shopt -s nullglob
            users_to_import=( "$user_directory"/* )
            shopt -u nullglob
            break
        else
            if [[ ! -f "$user_directory/$1" ]]; then
                die "Unkown user '$1'."
            fi
            users_to_import+=( "$user_directory/$1" )
            shift
        fi
    done
    for user_file in "${users_to_import[@]}"; do
        $GPG $PASSWORD_STORE_GPG_OPTS --import $user_file
    done
}

cmd_user_privy( ) {
    [[ $# -lt 2 ]] && die "Usage: $PROGRAM $COMMAND privy gpg-id secret-path"
    checked_user="$1"
    shift

    if ! [[ -f "$PREFIX/$USER_FOLDER/$checked_user" ]]; then
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        set_path_to_check "$1"
        if [[ -z "$PATH_TO_CHECK" ]]; then
            exit 1
        fi
        set_used_gpg_id_file "$PREFIX/$PATH_TO_CHECK"
        if ! [[ -f "$USED_GPG_ID_FILE" ]]; then
            die "Error: password store is not initialized. Try \"pass init\"."
        fi
        while read -r present_user; do
            if [[ "$present_user" == "$checked_user" ]]; then
                is_privy=1
            fi
        done < "$USED_GPG_ID_FILE"
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
    cmd_git push
}




cmd_user_induct() {
    [[ $# -lt 2 ]] && die "Usage: $PROGRAM $COMMAND user induct gpg-id dir..."
    local user="$1";
    if ! [[ -f "$PREFIX/$USER_FOLDER/$user" ]]; then
        die "Unknown user '$user'."
    fi
    shift;
    check_sneaky_paths "$@"
    local dirs_to_induct=();
    while [[ $# -gt 0 ]]; do
        if ! [[ -e "$PREFIX/$1" ]]; then
            mkdir -p "$PREFIX/$1"
        fi
        if [[ -d "$PREFIX/$1" ]]; then
            dirs_to_induct+=("$1")
        else
            die "Error: Given argument '$1' is not a directory."
        fi
        shift
    done

    for dir_to_induct in "${dirs_to_induct[@]}"; do
        add_recipient "$dir_to_induct" "$user"
    done

}

cmd_user_cabal() {
    [[ $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND user cabal path"
    local secret="$PREFIX/$1"
    check_sneaky_paths "$secret"
    set_used_gpg_id_file "$secret"
    if ! [[ -f "$USED_GPG_ID_FILE" ]]; then
        die "Error: password store is not initialized. Try \"pass init\"."
    fi
    cat "$USED_GPG_ID_FILE"
}

cmd_usage() {
	cat <<-_EOF
    Version $USER_VERSION management for the pass command.
	Usage:
        $PROGRAM $COMMAND init user-id repo-url
            Will clone the given repository and add the given user to its database.
	    $PROGRAM $COMMAND version
	        Show version information.
        $PROGRAM $COMMAND add gpg-id
            Add a user to the repository. Its public id will be stored
            in the $USER_FOLDER folder.
        $PROGRAM $COMMAND exists gpg-id...
            Will succeed if git is initilized the $USER_FOLDER folder itself and
            all listed user-ids are present.
        $PROGRAM $COMMAND list
            Lists all users registered in the repository.
        $PROGRAM $COMMAND ls
            Shorthand for the list command.
        $PROGRAM $COMMAND import [--all,-a] user-id...
            Will import public ids from the $USER_FOLDER folder into gpg.
        $PROGRAM $COMMAND privy user-id pass-name...
            Will succeed if all pass-name exist and the given user is listed
            to have access to these.
        $PROGRAM $COMMAND join user-id repo-url
            Will clone the given repository and add the given user to its database.
        $PROGRAM $COMMAND cabal pass-name
            Will list the users that have access to the given secret.
        $PROGRAM $COMMAND induct user-id pass-name...
            Will grant the specified user access to the given secrets.
        $PROGRAM $COMMAND help
            Show this help text.
	_EOF
}


[[ $# -lt 1 ]] && subcommand_fail "No subcommand given."

case "$1" in
    version) shift;     cmd_user_version "$@" ;;
    init) shift;        cmd_user_init "$@" ;;
    add) shift;         cmd_user_add "$@" ;;
    exists) shift;      cmd_user_exists "$@" ;;
    list|ls) shift;     cmd_user_list "$@" ;;
    import) shift;      cmd_user_import "$@" ;;
    privy) shift;       cmd_user_privy "$@" ;;
    join) shift;        cmd_user_join "$@" ;;
    cabal) shift;       cmd_user_cabal "$@" ;;
    induct) shift;      cmd_user_induct "$@" ;;
    help) shift;        cmd_user_help "$@" ;;
    *)              subcommand_fail "Unknown subcommand '$1'." ;;
esac
exit 0