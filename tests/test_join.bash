#!/user/bin/env bash

source common.bash

ALICE_DIR=$(setup_context alice)
as_alice() {
    context "$ALICE_DIR" "$@"
}

BOB_DIR=$(setup_context bob)
as_bob() {
    context "$BOB_DIR" "$@"
}

GIT_REPO=$(setup_repository)

echo "Test directories:"
echo "alice: $ALICE_DIR"
echo "bob: $BOB_DIR"
echo "got: $GIT_REPO"


as_alice pass init alice
as_alice pass git init
as_alice pass user add alice
as_alice pass git remote add origin "$GIT_REPO"
as_alice pass git push --set-upstream origin master

as_bob pass join "$GIT_REPO"
as_bob pass user add bob
as_bob pass user trust --all

