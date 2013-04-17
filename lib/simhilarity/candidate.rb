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

    # Calculate the score for this +Candidate+. The score is the {dice
    # coefficient}[http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient],
    # <tt>(2*c)/(a+b)</tt>.
    #
    # * +a+: the frequency weighted sum of the ngrams in a
    # * +b+: the frequency weighted sum of the ngrams in b
    # * +c+: the frequency weighted sum of the ngrams in (a & b)
    #
    # Lazily calculated and memoized.
    def score
      @score ||= begin
        c = (self.a.ngrams & self.b.ngrams)
        if c.length > 0
          a = self.a.ngrams_sum
          b = self.b.ngrams_sum
          c = matcher.ngrams_sum(c)
          (2.0 * c) / (a + b)
        else
          0
        end
      end
    end

    def to_s #:nodoc:
      "Candidate #{score}: #{a.inspect}..#{b.inspect}"
    end
  end
end
