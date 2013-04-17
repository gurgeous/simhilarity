require "bk"
require "set"

module Simhilarity
  # Match a set of needles against a haystack, in bulk. For example,
  # this is used if you want to match 50 new addresses against your
  # database of 1,000 known addresses.
  class Bulk < Matcher
    # Initialize a new Bulk matcher. See Matcher#initialize. Bulk adds
    # these options:
    #
    # * +candidates+: specifies which method to use for finding
    #   candidates. See the README for more details.
    # * +ngrams_overlaps+: Minimum number of ngram overlaps, defaults
    #   to 3.
    # * +simhash_max_hamming+: Maximum simhash hamming distance,
    #   defaults to 7.
    def initialize(options = {})
      super(options)
    end

    # Match each item in +needles+ to an item in +haystack+. Returns
    # an array of tuples, <tt>[needle, haystack, score]</tt>. Scores
    # range from 0 to 1, with 1 being a perfect match and 0 being a
    # terrible match.
    def matches(needles, haystack)
      # create Elements
      needles = import_list(needles)
      haystack = import_list(haystack)

      # set the corpus, to generate frequency weights
      self.corpus = (needles + haystack)

      # get candidate matches
      candidates = candidates(needles, haystack)

      # pick winners
      winners(needles, candidates)
    end

    protected

    # Find candidates from +needles+ & +haystack+. The method used
    # depends on the value of options[:candidates]
    def candidates(needles, haystack)
      method = options[:candidates]
      method ||= (needles.length * haystack.length < 200000) ? :all : :simhash
      method = "candidates_#{method}".to_sym
      if !respond_to?(method)
        raise "unsupported options[:candidates] #{options[:candidates].inspect}"
      end

      vputs "Using #{method}..."
      self.send(method, needles, haystack).map do |n, h|
        Candidate.new(self, n, h)
      end
    end

    # Return ALL candidates. This only works for small datasets.
    def candidates_all(needles, haystack)
      needles.product(haystack)
    end

    # Return candidates that overlap with three or more matching
    # ngrams. Only works for small datasets.
    def candidates_ngrams(needles, haystack)
      ngram_overlaps = options[:ngram_overlaps] || 3

      candidates = []
      veach(needles, " ngrams") do |n|
        ngrams_set = Set.new(n.ngrams)
        haystack.each do |h|
          count = 0
          h.ngrams.each do |ngram|
            if ngrams_set.include?(ngram)
              if (count += 1) == ngram_overlaps
                candidates << [n, h]
                break
              end
            end
          end
        end
      end
      candidates
    end

    # Find candidates that are close based on hamming distance between
    # the simhashes.
    def candidates_simhash(needles, haystack)
      max_hamming = options[:simhash_max_hamming] || 7

      # calculate this first so we get a nice progress bar
      veach(corpus, " simhash") { |i| i.simhash }

      # build the bk tree
      bk = BK::Tree.new(lambda { |a, b| Bits.hamming32(a.simhash, b.simhash) })
      veach(haystack, " bktree") { |i| bk.add(i) }

      # search for candidates with low hamming distance
      candidates = []
      veach(needles, " hamming") do |n|
        bk.query(n, max_hamming).each do |h, distance|
          candidates << [n, h]
        end
      end
      candidates
    end

    # walk candidates by score, pick winners
    def winners(needles, candidates)
      # calculate this first so we get a nice progress bar
      veach(candidates, "Scoring") { |i| i.score }

      # score the candidates
      candidates = candidates.sort_by { |i| -i.score }

      # walk them, eliminate dups
      seen = Set.new
      winners = candidates.map do |i|
        next if seen.include?(i.a) || seen.include?(i.b)
        seen << i.a
        seen << i.b
        i
      end.compact

      # build map from needle => candidate...
      needle_to_winner = { }
      winners.each { |i| needle_to_winner[i.a] = i }

      # so we can return in the original order
      needles.map do |i|
        if candidate = needle_to_winner[i]
          [ i.opaque, candidate.b.opaque, candidate.score ]
        else
          [ i.opaque, nil, nil ]
        end
      end
    end
  end
end
