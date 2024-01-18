#!/user/bin/env bash

source env_test.bash

info "Alice initalizes a pass and the underlining git repository."
alice "pass init alice"
alice "pass git init"
info "She adds secrets to the password store." \
     "These are saved for her has she initalized the user."
alice "echo \"SECRET_ONE\" | pass insert -e foo/kept_by_alice"
alice "echo \"SECRET_TWO\" | pass insert -e bar/shared_by_alice"
info "As she is not a user yet she is not privy to these passwords."
alice "pass privy alice foo" --fails
alice "pass privy alice bar" --fails
alice "pass privy alice foo bar" --fails

info "She adds herself to the users."
alice "pass user add alice"

info  "Thus becomes privy to the passwords created by her."
alice "pass privy alice foo"
alice "pass privy alice bar"
alice "pass privy alice foo bar"

info "She adds the remote repository as the origin and pushes her local state."
alice "pass git remote add origin $GIT_REPO"
alice "pass git push --set-upstream origin master"

info "Bob joins the repostory and adds himself to it."
bob "pass join $GIT_REPO"
bob "pass user add bob"
info "He imports all users present."
bob "pass user import --all"
info "He has no access to any passwords."
bob "pass privy bob foo" --fails
bob "pass privy bob unknown/folder" --fails
bob "pass privy bob bar/shared_by_alice" --fails
bob "pass privy bob foo bar" --fails
info "Bob pushes to the remote repository."
bob "pass git push"

info "Alice pulls his changes."

