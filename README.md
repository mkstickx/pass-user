# pass share

An extension for the [password store](https://www.passwordstore.org/) enabling multi-user settings.
The git repository used by the pass command is utilized for user management.


## commands

### pass user
#### add
`pass user add <gpg-id>` will add the given gpg id to the users

### pass join

`pass join <repository-url>` will check out the given git repository.



## files

### .users/
The users gpg keys will be stored in the `.users` folder in underlining git repository.
