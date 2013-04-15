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

    # Weighted sum of +ngrams+ via Matcher#ngrams_sum. Lazily
    # calculated.
    def ngrams_sum
      @ngrams_sum ||= matcher.ngrams_sum(ngrams)
    end

    # Generate a list of Candidates from +haystack+. Candidates are
    # generated for haystack items that have enough ngram overlaps.
    def candidates(haystack)
      ngrams_set = Set.new(ngrams)
      list = haystack.select { |i| is_candidate?(ngrams_set, i) }
      list = list.map { |i| Candidate.new(matcher, self, i) }
      list
    end

    def to_s #:nodoc:
      str
    end

    def inspect #:nodoc:
      str.inspect
    end

    protected

    # Is this +haystack+ a Candidate? True if there are a few ngrams
    # in common between us and the +haystack+.
    def is_candidate?(ngrams_set, haystack)
      count = 0
      haystack.ngrams.each do |ngram|
        if ngrams_set.include?(ngram)
          if (count += 1) == matcher.options[:candidate_overlaps]
            return true
          end
        end
      end
      false
    end
  end
end
