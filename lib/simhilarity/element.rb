require "set"

module Simhilarity
  # Internal wrapper around opaque items from user. This mostly exists
  # to cache stuff that's expensive, like the ngrams.
  class Element
    # matcher that owns this guy
    attr_reader :matcher

    # opaque object from the user
    attr_reader :opaque

    def initialize(matcher, opaque) #:nodoc:
      @matcher = matcher
      @opaque = opaque
    end

    # Text string generated from +opaque+ via Matcher#read. Lazily
    # calculated.
    def str
      @str ||= matcher.normalize(matcher.read(opaque))
    end

    # List of ngrams generated from +str+ via
    # Matcher#ngrams. Lazily calculated.
    def ngrams
      @ngrams ||= matcher.ngrams(str)
    end

    # Weighted frequency sum of +ngrams+ via
    # Matcher#ngrams_sum. Lazily calculated.
    def ngrams_sum
      @ngrams_sum ||= matcher.ngrams_sum(ngrams)
    end

    # Weighted simhash of +ngrams+ via Matcher#simhash. Lazily
    # calculated.
    def simhash
      @simhash ||= matcher.simhash(ngrams)
    end

    def to_s #:nodoc:
      str
    end

    def inspect #:nodoc:
      str.inspect
    end
  end
end
