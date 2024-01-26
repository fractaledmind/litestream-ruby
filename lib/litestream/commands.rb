require_relative "upstream"

module Litestream
  module Commands
    DEFAULT_DIR = File.expand_path(File.join(__dir__, "..", "..", "exe"))
    GEM_NAME = "litestream"

    # raised when the host platform is not supported by upstream litestream's binary releases
    class UnsupportedPlatformException < StandardError
    end

    # raised when the litestream executable could not be found where we expected it to be
    class ExecutableNotFoundException < StandardError
    end

    # raised when LITESTREAM_INSTALL_DIR does not exist
    class DirectoryNotFoundException < StandardError
    end

    def self.platform
      [:cpu, :os].map { |m| Gem::Platform.local.send(m) }.join("-")
    end

    def self.executable(exe_path: DEFAULT_DIR)
      litestream_install_dir = ENV["LITESTREAM_INSTALL_DIR"]
      if litestream_install_dir
        if File.directory?(litestream_install_dir)
          warn "NOTE: using LITESTREAM_INSTALL_DIR to find litestream executable: #{litestream_install_dir}"
          exe_path = litestream_install_dir
          exe_file = File.expand_path(File.join(litestream_install_dir, "litestream"))
        else
          raise DirectoryNotFoundException, <<~MESSAGE
            LITESTREAM_INSTALL_DIR is set to #{litestream_install_dir}, but that directory does not exist.
          MESSAGE
        end
      else
        if Litestream::Upstream::NATIVE_PLATFORMS.keys.none? { |p| Gem::Platform.match_gem?(Gem::Platform.new(p), GEM_NAME) }
          raise UnsupportedPlatformException, <<~MESSAGE
            litestream-ruby does not support the #{platform} platform
            Please install litestream following instructions at https://litestream.io/install
          MESSAGE
        end

        exe_file = Dir.glob(File.expand_path(File.join(exe_path, "*", "litestream"))).find do |f|
          Gem::Platform.match_gem?(Gem::Platform.new(File.basename(File.dirname(f))), GEM_NAME)
        end
      end

      if exe_file.nil? || !File.exist?(exe_file)
        raise ExecutableNotFoundException, <<~MESSAGE
          Cannot find the litestream executable for #{platform} in #{exe_path}

          If you're using bundler, please make sure you're on the latest bundler version:

              gem install bundler
              bundle update --bundler

          Then make sure your lock file includes this platform by running:

              bundle lock --add-platform #{platform}
              bundle install

          See `bundle lock --help` output for details.

          If you're still seeing this message after taking those steps, try running
          `bundle config` and ensure `force_ruby_platform` isn't set to `true`. See
          https://github.com/fractaledmind/litestream-ruby#check-bundle_force_ruby_platform
          for more details.
        MESSAGE
      end

      exe_file
    end

    def self.replicate(argv = {})
      if Litestream.configuration
        ENV["LITESTREAM_REPLICA_BUCKET"] = Litestream.configuration.replica_bucket
        ENV["LITESTREAM_ACCESS_KEY_ID"] = Litestream.configuration.replica_key_id
        ENV["LITESTREAM_SECRET_ACCESS_KEY"] = Litestream.configuration.replica_access_key
      end

      args = {
        "--config" => Rails.root.join("config", "litestream.yml").to_s
      }.merge(argv).to_a.flatten.compact

      command = [executable, "replicate", *args]
      puts command.inspect
      system(*command)
    end
  end
end
