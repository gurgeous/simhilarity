module Simhilarity
  module Candidates
    # default minimum number # of ngram overlaps with :ngrams
    DEFAULT_NGRAM_OVERLAPS = 3
    # default maximum hamming distance with :simhash
    DEFAULT_SIMHASH_MAX_HAMMING = 7

    # Find candidates from +needles+ & +haystack+. The method used
    # depends on the value of options[:candidates]
    def candidates(needles, haystack)
      # generate candidates
      candidates_method = candidates_method(needles, haystack)
      candidates = self.send(candidates_method, needles, haystack)

      # if these are the same, no self-dups
      if needles == haystack
        candidates = candidates.reject { |n, h| n == h }
      end

      # map and return
      candidates.map { |n, h| Candidate.new(n, h) }
    end

    # Select the method for finding candidates based on
    # options[:candidates].
    def candidates_method(needles, haystack)
      # pick the method
      method = options[:candidates]
      method ||= (needles.length * haystack.length < 200000) ? :all : :simhash
      case method
      when /^ngrams=(\d+)$/
        method = :ngrams
        options[:ngram_overlaps] = $1.to_i
      when /^simhash=(\d+)$/
        method = :simhash
        options[:simhash_max_hamming] = $1.to_i
      end

      method = "candidates_#{method}".to_sym
      if !respond_to?(method, true)
        raise "unsupported options[:candidates] #{options[:candidates].inspect}"
      end

      vputs "Using #{method} with needles=#{needles.length} haystack=#{haystack.length}..."
      method
    end

    # Return ALL candidates. This only works for small datasets.
    def candidates_all(needles, haystack)
      needles.product(haystack)
    end

    # Return candidates that overlap with three or more matching
    # ngrams. Only works for small datasets.
    def candidates_ngrams(needles, haystack)
      ngram_overlaps = options[:ngram_overlaps] || DEFAULT_NGRAM_OVERLAPS

      candidates = []
      veach(" ngrams #{ngram_overlaps}", needles) do |n|
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
      max_hamming = options[:simhash_max_hamming] || DEFAULT_SIMHASH_MAX_HAMMING

      # build or fetch @bk_tree
      bk = self.bk_tree

      # search for candidates with low hamming distance
      candidates = []
      veach(" hamming #{max_hamming}", needles) do |n|
        bk.query(n, max_hamming).each do |h, distance|
          candidates << [n, h]
        end
      end
      candidates
    end

  end
end
