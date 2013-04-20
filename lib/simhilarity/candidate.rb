module Simhilarity
  # A potential match between two +Elements+. It can calculate it's own score.
  class Candidate
    # matcher that owns this guy
    attr_reader :matcher

    # first half of the candidate pair - the needle.
    attr_reader :a

    # first half of the candidate pair - the haystack.
    attr_reader :b

    def initialize(matcher, a, b) #:nodoc:
      @matcher = matcher
      @a = a
      @b = b
    end

    # Ask the matcher to score this +Candidate+. Lazily calculated and
    # memoized.
    def score
      @score ||= @matcher.score(self)
    end

    def to_s #:nodoc:
      "Candidate #{score}: #{a.inspect}..#{b.inspect}"
    end
  end
end
