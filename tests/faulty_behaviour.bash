#!/user/bin/env bash

ACTORS="mallroy"
source lib/setup_test.bash

info "Any attempt to initialize or join the repository without an private key will fail."
mallroy "pass user init bob $GIT_REPO" --fails
mallroy "pass user join bob $GIT_REPO" --fails

end_of_test