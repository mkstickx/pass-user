#!/user/bin/env bash

ACTORS="alice"
source lib/setup_test.bash

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

end_of_test