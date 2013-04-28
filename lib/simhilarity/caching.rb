module Simhilarity
  module Caching
    CACHE_FILE = "/tmp/simhilarity_cache"
    CACHE_VERSION = "1"

    # Cache the +bk_tree+ in /tmp.
    def cache(bk_tree)
      File.open(CACHE_FILE, "wb") do |f|
        f.puts CACHE_VERSION
        f.puts cache_md5
        f.write Marshal.dump(bk_tree)
      end
    end

    # Uncache the bktree and return it. Returns nil if it's out of
    # date or doesn't exist.
    def uncache
      return nil if !File.exists?(CACHE_FILE)

      File.open(CACHE_FILE, "rb") do |f|
        version = f.gets.chomp
        return nil if version != CACHE_VERSION
        md5 = f.gets.chomp
        return nil if md5 != cache_md5
        Marshal.load(f.read)
      end
    end

    # Calculate the md5 checksum for +haystacks+. We use this to
    # determine if the cache is out of date.
    def cache_md5
      md5 = Digest::MD5.new
      @haystack.each { |i| md5 << i.str }
      md5.hexdigest
    end
  end
end
