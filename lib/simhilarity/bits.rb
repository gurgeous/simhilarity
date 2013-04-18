require "digest"

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
  end
end
