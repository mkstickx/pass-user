source lib/common.bash

ROOT=$(mktemp --tmpdir -d "test.pass-share.XXXXXXX")

ALICE_DIR=""
if [[ "$ACTORS" == *"alice"* ]]; then
    ALICE_DIR=$(setup_context "$ROOT" alice)
fi
alice() {
    context "alice" "$CYAN" "$ALICE_DIR" "$@"
}
BOB_DIR=""
if [[ "$ACTORS" == *"bob"* ]]; then
    BOB_DIR=$(setup_context "$ROOT" bob)
fi
bob() {
    context "bob" "$BLUE" "$BOB_DIR" "$@"
}
MALLROY_DIR=""
if [[ "$ACTORS" == *"mallroy"* ]]; then
    MALLROY_DIR=$(setup_context "$ROOT" mallroy)
fi
mallroy() {
    context "mallroy" "$MANGENTA" "$MALLROY_DIR" "$@"
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