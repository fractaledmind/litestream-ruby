module Litestream
  module Upstream
    VERSION = "0.5.17"

    # rubygems platform name => upstream release filename
    NATIVE_PLATFORMS = {
      "aarch64-linux" => "litestream-#{VERSION}-linux-arm64.tar.gz",
      "arm64-darwin" => "litestream-#{VERSION}-darwin-arm64.tar.gz",
      "arm64-linux" => "litestream-#{VERSION}-linux-arm64.tar.gz",
      "x86_64-darwin" => "litestream-#{VERSION}-darwin-x86_64.tar.gz",
      "x86_64-linux" => "litestream-#{VERSION}-linux-x86_64.tar.gz"
    }

    CHECKSUMS = {
      "litestream-0.5.17-linux-x86_64.tar.gz" => "cfb371176d164437ae869f8351cfde49bd1804ae71c61923f75c9cba9c9c006d",
      "litestream-0.5.17-linux-arm64.tar.gz" => "f8ca4a050095c1efbda2c4365172e61bf9d955ea0d9ac42f448b52e51819baa5",
      "litestream-0.5.17-darwin-x86_64.tar.gz" => "891875af09db152e93a4b31a8a79f538ce7ce702c132803cfe0a831e7cb1b7db",
      "litestream-0.5.17-darwin-arm64.tar.gz" => "e211f68ff7658d19f193f2914417afdf8f89a053ff8f263e5d6b3b1d3bbc7b08"
    }

    def self.download_url(filename)
      "https://github.com/benbjohnson/litestream/releases/download/v#{VERSION}/#{filename}"
    end
  end
end
