require "set"

module Simhilarity
  # Match a set of needles against a haystack, in bulk. For example,
  # this is used if you want to match 50 new addresses against your
  # database of 1,000 known addresses.
  class Bulk < Matcher
    # Initialize a new Bulk matcher. See Matcher#initialize. Bulk adds
    # these options:
    #
    # +candidate_overlaps:+ number of ngram required to generate a candidate
    def initialize(options = {})
      super(options)

      # by default, require at least 3 ngram overlaps to create
      # Candidates from needle/haystack pairs
      options[:candidate_overlaps] ||= 3
    end

    # Match each item in +needles+ to an item in +haystack+. Returns
    # an array of tuples, <tt>[needle, haystack, score]</tt>. Scores
    # range from 0 to 1, with 1 being a perfect match and 0 being a
    # terrible match.
    def matches(needles, haystack)
      needles = import_list(needles)
      haystack = import_list(haystack)

      # set the corpus, to generate weights
      self.corpus = (needles + haystack)

      # get set of candidates
      candidates = needles.map { |i| i.candidates(haystack) }.flatten
      candidates = candidates.sort_by { |i| -i.score }

      # walk candidates by score, pick winners
      seen = Set.new
      winners = candidates.map do |i|
        next if seen.include?(i.a) || seen.include?(i.b)
        seen << i.a
        seen << i.b
        i
      end.compact

      # build map from needle => candidate, then return in the original
      # order!
      needle_to_winner = { }
      winners.each { |i| needle_to_winner[i.a] = i }

      needles.map do |i|
        if candidate = needle_to_winner[i]
          [ i.opaque, candidate.b.opaque, candidate.score ]
        end
      end
    end
  end
end
