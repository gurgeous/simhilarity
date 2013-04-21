module Simhilarity
  # A potential match between two +Elements+. It can calculate it's own score.
  class Candidate
    # first half of the candidate pair - the needle.
    attr_reader :a

    # first half of the candidate pair - the haystack.
    attr_reader :b

    # the score between these two candidates
    attr_accessor :score

    def initialize(a, b) #:nodoc:
      @a = a
      @b = b
    end

    def to_s #:nodoc:
      "Candidate #{score}: #{a.inspect}..#{b.inspect}"
    end
  end
end
