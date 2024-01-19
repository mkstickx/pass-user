source lib/common.bash

ROOT=$(mktemp --tmpdir -d "test.pass-share.XXXXXXX")

ALICE_DIR=$(setup_context "$ROOT" alice)
alice() {
    context "alice" "$MANGENTA" "$ALICE_DIR" "$@"
}

BOB_DIR=$(setup_context "$ROOT" bob)
bob() {
    context "bob" "$CYAN" "$BOB_DIR" "$@"
}
REPO_NAME="repository.git"

GIT_REPO=$(setup_repository "$ROOT" "$REPO_NAME")

info() {
    while [[ $# -gt 0 ]]; do
        echo "$1" | out_fmt "$UNDERLINE" "$YELLOW"
        shift
    done
}

echo "Test directory: $ROOT"

end_of_test() {
    echo "--- SUCCESSFULLY FINISHED TEST ---" | out_fmt "$BOLD" "$GREEN"
}