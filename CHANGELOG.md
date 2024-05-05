## [Unreleased]

## [0.10.0] - 2024-05-05

- Remove the verification command and Rake task and replace with a better `Litestream.verify!` method ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/28))
- Add a mountable engine for a web dashboard overview of the Litestream process ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/29))
- Add a Puma plugin ([@zachasme](https://github.com/fractaledmind/litestream-ruby/pull/22))

## [0.9.0] - 2024-05-04

- Improve the verification task by exiting with a proper status code and printing out a more clear message ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/27))

## [0.8.0] - 2024-05-02

- Improve the verification task by returning number of tables, indexes, and rows ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/26))

## [0.7.2] - 2024-05-02

- Ensure that the `Logfmt` gem is available to parse the Litestream command output

## [0.7.1] - 2024-05-02

- Fix typo in executing Litestream commands

## [0.7.0] - 2024-05-02

- Commands return parsed Litestream output or error if Litestream errors ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/25))

## [0.6.0] - 2024-04-30

- Don't provide a default output for the restore command, only for the verify command ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/24))
- Remove a typo from upstream.rb ([@skatkov](https://github.com/fractaledmind/litestream-ruby/pull/21))

## [0.5.5] - 2024-04-30

- Fix bug with forwarding arguments to the Rake tasks being symbols when passed to `exec` ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/23))

## [0.5.4] - 2024-04-18

- Remove old usage of config.database_path ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/18))
- Ensure that executing a command synchronously returns output ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/20))

## [0.5.3] - 2024-04-17

- Fix bug with Rake tasks not handling new kwarg method signatures of commands

## [0.5.2] - 2024-04-17

- Add a `verify` command and Rake task ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/16))
- Allow any command to be run either synchronously or asynchronously ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/17))

## [0.5.1] - 2024-04-17

- Add `databases`, `generations`, and `snapshots` commands ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/15))

## [0.5.0] - 2024-04-17

- Add a `restore` command ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/14))
- Ensure that the #replicate method only sets unset ENV vars and doesn't overwrite them ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/13))

## [0.4.0] - 2024-04-12

- Generate config file with support for multiple databases ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/7))

## [0.3.3] - 2024-01-06

- Fork the Litestream process to minimize memory overhead ([@supermomonga](https://github.com/fractaledmind/litestream-ruby/pull/6))

## [0.1.0] - 2023-12-11

- Initial release
