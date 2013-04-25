module Simhilarity
  module Candidates
    # default minimum number # of ngram overlaps with :ngrams
    DEFAULT_NGRAM_OVERLAPS = 3

    # default maximum hamming distance with :simhash
    DEFAULT_SIMHASH_MAX_HAMMING = 7

    # Find candidates from +needles+ & +haystack+. The method used
    # depends on the value of +candidates+
    def candidates_for(needles)
      # generate candidates
      candidates_method = candidates_method(needles)
      candidates = self.send(candidates_method, needles)

      # if these are the same, no self-dups
      if needles == haystack
        candidates = candidates.reject { |n, h| n == h }
      end

      # map and return
      candidates.map { |n, h| Candidate.new(n, h) }
    end

    # Select the method for finding candidates based on +candidates+.
    def candidates_method(needles)
      # pick the method
      method = self.candidates
      method ||= (needles.length * haystack.length < 200000) ? :all : :simhash
      case method
      when /^ngrams=(\d+)$/
        method = :ngrams
        self.ngram_overlaps = $1.to_i
      when /^simhash=(\d+)$/
        method = :simhash
        self.simhash_max_hamming = $1.to_i
      end

      method = "candidates_#{method}".to_sym
      if !respond_to?(method, true)
        raise "unsupported candidates #{candidates.inspect}"
      end

      vputs "Using #{method} with needles=#{needles.length} haystack=#{haystack.length}..."
      method
    end

    # Return ALL candidates. This only works for small datasets.
    def candidates_all(needles)
      needles.product(haystack)
    end

    # Return candidates that overlap with three or more matching
    # ngrams. Only works for small datasets.
    def candidates_ngrams(needles)
      ngram_overlaps = self.ngram_overlaps || DEFAULT_NGRAM_OVERLAPS

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
    def candidates_simhash(needles)
      max_hamming = self.simhash_max_hamming || DEFAULT_SIMHASH_MAX_HAMMING

      # search for candidates with low hamming distance
      candidates = []
      veach(" hamming #{max_hamming}", needles) do |n|
        bk_tree.query(n, max_hamming).each do |h, distance|
          candidates << [n, h]
        end
      end
      candidates
    end
  end
end
