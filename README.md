# pass share

An extension for the [password store](https://www.passwordstore.org/) enabling multi-user settings.
The the pass command can expose its underlining data structure as a git repository. This extension implements a rudimentary user management by placing the participants public keys in the `.users` directory of this repository.

The existence of an, initially empty, git repository is a prerequisite to use the shared password store.

No trust related actions will be preformed by this plugin.

For detailed examples of intended workflows also have a look at the tests.

## commands
All commands of this plugin are implemented as subcommands of the `users` sub-command.
### Initialization commands.
The following commands can be used start using the shared password store.
#### init
The `init` command is used when first initializing the shared password store as the primary user.
The following example would initialize the `secrets.git` repository on  the `example.dd` server with *alice* as the main user.

```
pass user init alice git@examle.dd:secrets.git
```

The following steps will be preformed by the command:
- Initialize the password store by calling `pass init alice`. Thus setting the *alice* as the main user id.
- Initialize the underlining git repository by calling `pass git init`.
- Set the the given repository as gits origin.
- Add *alice* public key to the `.users` directory.
- Push these changes to the remote when successful.

#### join

The following example would add *alice* to the users of the `secrets.git` repository on  the `example.dd` server.



```
pass user join alice git@example.dd:secrets.git
```

**NOTE:** This also works if the repository is not initialized yet.

The following steps will be preformed:

- Check out the given git repository as the underling repository used by `pass`.
- Add *alice* public key to the `.users` directory, within the repository.
- Push these changes to the remote when successful.


### User Management
The following command can by used to manage the users of the shared password store.

#### exists
The command
```
pass user exists alice bob
```
will return successful if the user *alice* and *bob* are booth registered in the user management.

The using command
```
pass user exists
```
without any usernames specified, can be used to check if the user management was initialized.


#### add
The command
```
pass user add bob
```
will add the public key named *bob* from your local gpg-keyring to the users of the repository.
This is usually done during the *init* or *join* command.

#### import
The command
```
pass user import alice bob
```
will import the public keys for *alice* and *bob* from the repository to your gpg-keyring.

The `--all` flag can be used to import all present public keys.

```
pass user import --all
```

**NOTE:** No trust related actions are preformed. Depending on your trust policy you will need to perform additional steps to use these keys.

#### list
The list command will list all registered users.

```
pass user list
```

A shortcut for this is the `ls` command.

```
pass user ls
```

### Secret Management


#### cabal

The command

```
pass user cabal foo
```

will list all users having access to the passwords stored in the *foo* folder.

#### induct
The command

```
pass user induct bob foo bar
```

will give the user *bob* access to the secrets stored in the *foo* and the *bar* directories.
To perform this action the following conditions must be met:
- You need to have access to the specified directories yourself.
- You need to have imported (and trusted) the specified users public-key.


#### privy
The command

```
pass user privy bob foo bar
```

will return successfully if the user *bob* should have access to the secrets stored in the *foo* and *bar* folder.

**NOTE:** It is not checked if the user has actual access to these secrets. Any inconsistency here indicates something went wrong when using the *induct* command.



## files

### .users/
The users public gpg keys will be stored in the `.users` folder.
