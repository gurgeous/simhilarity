require "set"

module Simhilarity
  # Calculate the similarity score for pairs of items, one at a time.
  class Single < Matcher
    # See Matcher#initialize.
    def initialize(options = {})
      super(options)
    end

    # Calculate the similarity score for these two items. Scores range
    # from 0 to 1, with 1 being a perfect match and 0 being a terrible
    # match. For best results, call #corpus= first.
    def score(a, b)
      Candidate.new(self, element_for(a), element_for(b)).score
    end
  end
end
