## [Unreleased]

- The Puma plugin stops Puma when Litestream exits, as documented. The monitor was registered from the booted callback, after Puma had already started its background threads, so it never ran (same fix as rails/solid_queue@5d200d0).

## [0.16.0] - 2026-10-13

Breaking: this release bundles Litestream 0.5, which changes the backup format, the config shape and the CLI. Read "Upgrading from 0.3" in the README before upgrading. Stay on 0.15.x for Litestream 0.3, including age encryption.

- Bundle Litestream 0.5.17, with each release archive verified against a pinned SHA-256 checksum when packaging ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/78))
- Replace the `generations`, `snapshots` and `wal` methods and rake tasks with `ltx` and `status`; the removed ones raise with a pointer to `ltx` ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/78))
- Show each database's local status and LTX files in the dashboard ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/78))
- Generate Litestream 0.5 config, with one `replica:` per database and a global `snapshot:` block for interval and retention ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/78))
- Parse Litestream 0.5 tables whose headers and values contain spaces, as `status` has ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/81))
- Accept `-flag value` in rake task arguments, so `litestream:restore -- ... -o path` no longer aborts after restoring ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/83))
- Document Litestream's `logging:` block and passing a credentials file into a Kamal container ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/83))

## [0.15.0] - 2026-10-13

- Run Litestream commands without a shell, so arguments with spaces stay intact, and raise `Litestream::Commands::CommandFailedException` when a command exits non-zero instead of returning empty output; add `timeout:` and, for Litestream 0.5, `json: true` ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/76))
- Stop replication when Puma stops: the Puma plugin holds the pid of the litestream process itself ([@cole-robertson](https://github.com/fractaledmind/litestream-ruby/pull/77))
- Find the replicate process on Alpine and on images without `ps` by reading `/proc` on Linux ([@jherdman](https://github.com/fractaledmind/litestream-ruby/pull/68))
- Render the dashboard in the engine's own layout when the base controller declares one ([@fcatuhe](https://github.com/fractaledmind/litestream-ruby/pull/72))
- Raise the timeout error, not `Errno::EPERM`, when a command times out on macOS ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/80))

## [0.14.0] - 2025-06-14

- Change async behaviour of replicate and other commands ([@hschne](https://github.com/fractaledmind/litestream-ruby/pull/62))

## [0.13.0] - 2025-06-03

- Adds ability to configure default config path ([@rossta](https://github.com/fractaledmind/litestream-ruby/pull/54))
- Fix replication process detection ([@hschne](https://github.com/fractaledmind/litestream-ruby/pull/63))
- Remove locale check ([@hschne](https://github.com/fractaledmind/litestream-ruby/pull/64))
- Make base controller class configurable ([@zachasme](https://github.com/fractaledmind/litestream-ruby/pull/60))
- Support configuring replica region and endpoint ([@MatheusRich](https://github.com/fractaledmind/litestream-ruby/pull/58))
- configurable sleep time for Litestream.verify! ([@spinosa](https://github.com/fractaledmind/litestream-ruby/pull/59))
- docs: update README for restoration ([@oandalib](https://github.com/fractaledmind/litestream-ruby/pull/52))
- Build the aarch64-linux gem ([@fcatuhe](https://github.com/fractaledmind/litestream-ruby/pull/56))
- Add dark mode to dashboard ([@visini](https://github.com/fractaledmind/litestream-ruby/pull/47))

## [0.12.0] - 2024-09-06

- Add `wal` command ([alxvernier](https://github.com/fractaledmind/litestream-ruby/pull/41))
- Support configuration of custom `systemctl status` command ([rossta](https://github.com/fractaledmind/litestream-ruby/pull/39))
- Fix litestream showing as "not running" in Docker ([AxelTheGerman](https://github.com/fractaledmind/litestream-ruby/pull/44))
Update config example in README ([jgsheppa](https://github.com/fractaledmind/litestream-ruby/pull/45))

## [0.11.2] - 2024-09-06

- Simplify the getters to not use memoization

## [0.11.1] - 2024-09-06

- Ensure the litestream initializer handles `nil`s

## [0.11.0] - 2024-06-21

- Add a default username for the Litestream engine ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/commit/91c4de8b85be01f8cfd0cc2bf0027a6c0d9f3aaf))
- Add a verification job ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/36))

## [0.10.5] - 2024-06-21

- Fix Litestream.replicate_process for `systemd` ([@rossta](https://github.com/fractaledmind/litestream-ruby/pull/32))

## [0.10.4] - 2024-06-21

- Make engine available in published gem pkg ([@rossta](https://github.com/fractaledmind/litestream-ruby/pull/31))

## [0.10.3] - 2024-06-10

- Loading Rake tasks in the engine has them execute twice, so remove

## [0.10.2] - 2024-06-10

- Fix whatever weird thing is up with "e.g." breaking the Rake task descriptions

## [0.10.1] - 2024-05-05

- Ensure `verify!` reports the database that failed and returns true if verification passes ([@fractaledmind](https://github.com/fractaledmind/litestream-ruby/pull/30))

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
