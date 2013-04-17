module Simhilarity
  module Bits
    # Calculate the {hamming
    # distance}[http://en.wikipedia.org/wiki/Hamming_distance] between
    # two integers. Not particularly fast.
    def self.hamming(a, b)
      x, d = 0, a ^ b
      while d > 0
        x += 1
        d &= d - 1
      end
      x
    end

    HAMMING8  = (0..0xff).map { |i| Bits.hamming(0, i) }
    HAMMING16 = (0..0xffff).map { |i| HAMMING8[(i >> 8) & 0xff] + HAMMING8[(i >> 0) & 0xff] }

    # Calculate the {hamming
    # distance}[http://en.wikipedia.org/wiki/Hamming_distance] between
    # two 32 bit integers using a lookup table. This is fast.
    def self.hamming32(a, b)
      x = a ^ b
      a = (x >> 16) & 0xffff
      b = (x >>  0) & 0xffff
      HAMMING16[a] + HAMMING16[b]
    end

    # can't rely on ruby hash, because it's not consistent across
    # sessions. Let's just use MD5.
    def self.nhash(ngram)
      @hashes ||= { }
      @hashes[ngram] ||= Digest::MD5.hexdigest(ngram).to_i(16)
    end

    # Calculate the frequency weighted
    # simhash[http://matpalm.com/resemblance/simhash/] of the
    # +ngrams+.
    def self.simhash32(freq, ngrams)
      # array of bit sums
      bits = Array.new(32, 0)

      # walk bits of ngram's hash, increase/decrease bit sums
      ngrams.each do |ngram|
        f = freq[ngram]
        hash = nhash(ngram)
        (0...32).each do |i|
          bits[i] += (((hash >> i) & 1) == 1) ? f : -f
        end
      end

      # calculate simhash based on whether bit sums are negative or
      # positive
      simhash = 0
      (0...32).each do |bit|
        simhash |= (1 << bit) if bits[bit] > 0
      end
      simhash
    end
  end
end
