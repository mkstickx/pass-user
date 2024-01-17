
SRC_DIR=$(cd ../src && pwd)

function setup_context() {
    local PASS_USER="$1"
    local USER_DIRECTORY=$(mktemp --tmpdir -d "pass-share-test.$PASS_USER.XXXXXXX")
    local GPG_HOME="$USER_DIRECTORY/gnupg"
    mkdir "$GPG_HOME"
    chmod 700 "$GPG_HOME"
    gpg \
        --batch \
        --homedir "$GPG_HOME" \
        --passphrase "" \
        --pinentry-mode loopback \
        --quick-gen-key  "$PASS_USER" default default
    echo "$USER_DIRECTORY"
}

setup_repository() {
    REPO_DIR=$(mktemp --tmpdir -d "pass-share.git.XXXXXXX")
    git init --bare "$REPO_DIR/repo.git" &> /dev/null
    echo "$REPO_DIR/repo.git"
}

function context() {
    local USER_DIRECTORY=$1
    shift
    PASSWORD_STORE_DIR="$USER_DIRECTORY/store" \
    PASSWORD_STORE_ENABLE_EXTENSIONS=true \
    PASSWORD_STORE_EXTENSIONS_DIR="$SRC_DIR" \
    PASSWORD_STORE_GPG_OPTS=" --homedir $USER_DIRECTORY/gnupg " \
    "$@"
}