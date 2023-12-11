# litestream-ruby

[Litestream](https://litestream.io/) is a standalone streaming replication tool for SQLite. This gem provides a Ruby interface to Litestream.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add litestream

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install litestream

After installing the gem, run the installer:

    $ rails generate litestream:install

The installer will create a configuration file at `config/litestream.yml`, an initializer file for configuring the gem at `config/initializers/litestream.rb`, as well as a `Procfile` so that you can run the Litestream replication process alongside your Rails application in production.

This gem wraps the standalone executable version of the [Litestream](https://litestream.io/install/source/) utility. These executables are platform specific, so there are actually separate underlying gems per platform, but the correct gem will automatically be picked for your platform. Litestream itself doesn't support Windows, so this gem doesn't either.

Supported platforms are:

* arm64-darwin (macos-arm64)
* x86_64-darwin (macos-x64)
* arm64-linux (linux-arm64)
* x86_64-linux (linux-x64)

### Using a local installation of `litestream`

If you are not able to use the vendored standalone executables (for example, if you're on an unsupported platform), you can use a local installation of the `litestream` executable by setting an environment variable named `LITESTREAM_INSTALL_DIR` to the directory containing the executable.

For example, if you've installed `litestream` so that the executable is found at `/usr/local/bin/litestream`, then you should set your environment variable like so:

``` sh
LITESTREAM_INSTALL_DIR=/usr/local/bin
```

This also works with relative paths. If you've installed into your app's directory at `./.bin/litestream`:

``` sh
LITESTREAM_INSTALL_DIR=.bin
```

## Usage

### Configuration

You configure the Litestream executable through the [`config/litestream.yml` file](https://litestream.io/reference/config/), which is a standard Litestream configuration file as if Litestream was running in a traditional installation.

The gem streamlines the configuration process by providing a default configuration file for you. This configuration file will backup one application database to one replication bucket. In order to ensure that no secrets are stored in plain-text in your repository, this configuration file leverages Litestream's support for environment variables. The default configuration file looks like this:

```yaml
dbs:
  - path: $LITESTREAM_DATABASE_PATH
    replicas:
      - url: $LITESTREAM_REPLICA_URL
        access-key-id: $LITESTREAM_ACCESS_KEY_ID
        secret-access-key: $LITESTREAM_SECRET_ACCESS_KEY
```

The gem also provides a default initializer file at `config/initializers/litestream.rb` that allows you to configure these four environment variables referenced in the configuration file in Ruby. By providing a Ruby interface to these environment variables, you can use any method of storing secrets that you prefer. For example, the default generated file uses Rails' encrypted credentials to store your secrets:

```ruby
litestream_credentials = Rails.application.credentials.litestream
Litestream.configure do |config|
  config.database_path = ActiveRecord::Base.connection_db_config.database
  config.replica_url = litestream_credentials.replica_url
  config.replica_key_id = litestream_credentials.replica_key_id
  config.replica_access_key = litestream_credentials.replica_access_key
end
```

However, if you need manual control over the Litestream configuration, you can manually edit the `config/litestream.yml` file. The full range of possible configurations are covered in Litestream's [configuration reference](https://litestream.io/reference/config/).

### Replication

By default, the gem will create or append to a `Procfile` to start the Litestream process via the gem's provided `litestream:replicate` rake task. This rake task will automatically load the configuration file and set the environment variables before starting the Litestream process.

Again, however, you can take full manual control over the replication process and simply run the `litestream replicate --config config/litestream.yml` command to start the Litestream process. Since the gem installs the native executable via Bundler, the `litestream` command will be available in your `PATH`.

The full set of commands available to the `litestream` executable are covered in Litestream's [command reference](https://litestream.io/reference/). Currently, only the `replicate` command is provided as a rake task by the gem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

For maintainers, to release a new version, run `bin/release $VERSION`, which will create a git tag for the version, push git commits and tags, and push all of the platform-specific `.gem` files to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fractaledmind/litestream-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/fractaledmind/litestream-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Litestream project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fractaledmind/litestream-ruby/blob/main/CODE_OF_CONDUCT.md).
