require "test_helper"

class TestUpstream < ActiveSupport::TestCase
  def test_every_native_platform_has_a_checksum
    Litestream::Upstream::NATIVE_PLATFORMS.each_value do |filename|
      assert Litestream::Upstream::CHECKSUMS.key?(filename), "missing checksum for #{filename}"
    end
  end

  def test_release_urls_use_version_tag_and_unprefixed_filenames
    Litestream::Upstream::NATIVE_PLATFORMS.each_value do |filename|
      assert_equal "https://github.com/benbjohnson/litestream/releases/download/v0.5.17/#{filename}", Litestream::Upstream.download_url(filename)
      refute filename.start_with?("litestream-v")
    end
  end
end
