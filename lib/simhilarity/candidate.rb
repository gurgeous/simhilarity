module Simhilarity
  # A potential match between two +Elements". It can calculate it's own score.
  class Candidate
    # Owner for this guy.
    attr_reader :matcher

    # Needle.
    attr_reader :a

    # Haystack.
    attr_reader :b

    def initialize(matcher, a, b)
      @matcher = matcher
      @a = a
      @b = b
    end

    # Calculate the score for this +Candidate+. We calculate three values:
    #
    # * +a+: the weighted sum of the ngrams in a
    # * +b+: the weighted sum of the ngrams in b
    # * +c+: the weighted sum of the ngrams in (a & b)
    #
    # The final score is the dice coefficient, +(2*c)/(a+b)+. Lazily
    # calculated.
    def score
      @score ||= begin
        a = self.a.ngrams_sum
        b = self.b.ngrams_sum
        c = matcher.ngrams_sum(self.a.ngrams & self.b.ngrams)
        (2.0 * c) / (a + b)
      end
    end

    def to_s
      "Candidate #{score}: #{a.inspect}..#{b.inspect}"
    end
  end
end
