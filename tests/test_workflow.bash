#!/user/bin/env bash

source lib/env_test.bash

info "Alice initalizes a pass and the underlining git repository."
alice "pass init alice"
alice "pass git init"



info "She adds secrets to the password store." \
     "These are saved for her has she initalized the user."
alice "echo \"SECRET_FOO\" | pass insert -e for_alice_only/foo"
alice "echo \"SECRET_BAR\" | pass insert -e shared/bar"

info "User mangement is not initialized yet."
alice "pass user exists" --fails
alice "pass user exists alice" --fails

info "As she is not a user yet she is not privy to these passwords."
alice "pass user privy alice for_alice_only" --fails
alice "pass show for_alice_only/foo" --output "SECRET_FOO"
alice "pass user privy alice shared" --fails
alice "pass show shared/bar" --output "SECRET_BAR"
alice "pass user privy alice for_alice_only shared" --fails
alice "pass user privy alice unknown_path" --fails

info "She adds herself to the users."
alice "pass user add alice"

info "Thus she initializes the user management and " \
     " becomes privy to the passwords created by her."

alice "pass user exists"
alice "pass user exists alice"
alice "pass user privy alice for_alice_only"
alice "pass user privy alice shared"
alice "pass user privy alice for_alice_only shared"
alice "pass user privy alice unknown_path" --fails

info "Bob is not present yet."
alice "pass user exists bob" --fails

info "She adds the remote repository as the origin and pushes her local state."
alice "pass git remote add origin $GIT_REPO"
alice "pass git push --set-upstream origin master"

info "Bob joins the repostory and adds himself to it."
bob "pass user join bob $GIT_REPO"

info "He imports all users present."
bob "pass user import --all"

info "He is not privy concerning any passwords and can not read them."
bob "pass user privy bob for_alice_only" --fails
bob "pass user cabal for_alice_only" --output "alice"
bob "pass show for_alice_only/foo" --fails
bob "pass user privy bob shared" --fails
bob "pass show shared/bar" --fails
bob "pass user privy bob for_alice_only shared" --fails
bob "pass user privy bob unknown_path" --fails

info "He can create a secret for alice, but he will not be able to read it."
bob "echo \"I LOVE YOU\" | pass insert -e for_alice_only/bar"
bob "pass user privy bob for_alice_only/bar" --fails
bob "pass show for_alice_only/bar" --fails

info "Bob pushes to the remote repository."
bob "pass git push"

info "Alice pulls his changes and can read the password he created for her."
alice "pass git pull"
alice "pass show for_alice_only/bar" --output "I LOVE YOU"


info "Alice decides to share some secrets with bob."
alice "pass user import bob"
alice "pass user induct bob shared"
alice "echo \"I LOVE YOU TOO\" | pass insert -e shared/foo"
alice "pass git push"

info "Bob can access these secrets after pulling the git."
bob "pass git pull"
bob "pass user cabal shared" --output "alice" "bob"
bob "pass user privy bob shared"
bob "pass user privy bob shared for_alice_only"
bob "pass show shared/bar" --output "SECRET_BAR"
bob "pass show shared/foo" --output "I LOVE YOU TOO"


end_of_test
