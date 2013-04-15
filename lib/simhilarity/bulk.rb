require "set"

module Simhilarity
  # Match a set of needle items against a set of haystack items, in
  # bulk. For example, this is used if you want to match 50 new
  # addresses against your database of 1,000 known addresses.
  class Bulk < Matcher
    # Initialize a new Bulk matcher - See Matcher#initialize.
    def initialize(options = {})
      super(options)

      # by default, require at least 3 ngram overlaps to create
      # Candidates from needle/haystack pairs
      options[:candidate_overlaps] ||= 3
    end

    # Match each item in +needle+ to an item in +haystack+. Returns an
    # array of tuples, [needle, haystack, score]. Simhilarity scores
    # range from 0 to 1, with 1 being a perfect match and 0 being a
    # terrible match.
    def matches(needle, haystack)
      needle = import_list(needle)
      haystack = import_list(haystack)

      # set the corpus, to generate weights
      self.corpus = (needle + haystack)

      # get set of candidates
      candidates = needle.map { |i| i.candidates(haystack) }.flatten
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

      needle.map do |i|
        if candidate = needle_to_winner[i]
          [ i.opaque, candidate.b.opaque, candidate.score ]
        end
      end
    end
  end
end
