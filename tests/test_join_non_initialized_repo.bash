#!/user/bin/env bash

ACTORS="alice,bob"
source lib/env_test.bash

info "Bob joins the non initialized repository."
bob "pass user join bob $GIT_REPO"

info "The user management is already initialized."
bob "pass user exists"
bob "pass user exists bob"


info "Alice initializes the repository, thus becoming the main user."
alice "pass user init alice $GIT_REPO"
alice "pass user exists alice"
alice "pass user privy alice /"

info "Alice imports bobs key."
alice "pass user import bob"

info "Alice adds some secrets to the repository"
alice "echo \"SECRET_FOO\" | pass insert -e for_alice_only/foo"
alice "pass user induct bob shared"
alice "echo \"SECRET_BAR\" | pass insert -e shared/bar"
alice "pass git push"

info "Bob has access to some of these secrets."
bob "pass git pull"
bob "pass show for_alice_only/foo" --fails
bob "pass show shared/bar" --output "SECRET_BAR"

end_of_test