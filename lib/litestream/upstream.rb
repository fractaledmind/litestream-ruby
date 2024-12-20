module Litestream
  module Upstream
    VERSION = "v0.3.13"

    # rubygems platform name => upstream release filename
    NATIVE_PLATFORMS = {
      "aarch64-linux" => "litestream-#{VERSION}-linux-arm64.tar.gz",
      "arm64-darwin" => "litestream-#{VERSION}-darwin-arm64.zip",
      "arm64-linux" => "litestream-#{VERSION}-linux-arm64.tar.gz",
      "x86_64-darwin" => "litestream-#{VERSION}-darwin-amd64.zip",
      "x86_64-linux" => "litestream-#{VERSION}-linux-amd64.tar.gz"
    }
  end
end
