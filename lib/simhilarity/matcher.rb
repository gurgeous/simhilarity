require "bk"
require "set"
require "progressbar"

module Simhilarity
  class Matcher
    include Simhilarity::Candidates
    include Simhilarity::Score

    # If true, show progress bars and timing
    attr_accessor :verbose

    # Proc for turning opaque items into strings.
    attr_accessor :reader

    # Proc for normalizing strings.
    attr_accessor :normalizer

    # Proc for generating ngrams.
    attr_accessor :ngrammer

    # Proc for scoring ngrams.
    attr_accessor :scorer

    # Specifies which method to use for finding candidates. See the
    # README for more details.
    attr_accessor :candidates

    # Minimum number of ngram overlaps, defaults to 3 (for candidates
    # = :ngrams)
    attr_accessor :ngram_overlaps

    # Ngram frequency weights from the haystack, or 1 if the ngram
    # isn't in the haystack.
    attr_accessor :freq

    # Maximum simhash hamming distance, defaults to 7. (for candidates
    # = :simhash)
    attr_accessor :simhash_max_hamming

    # Set the haystack. Calculates ngram frequencies (#freq) for
    # future scoring.
    def haystack=(haystack)
      @haystack = import_list(haystack)

      @bitsums = { }
      @bk_tree = nil

      # calculate ngram counts for the haystack
      counts = Hash.new(0)
      veach("Haystack", @haystack) do |element|
        element.ngrams.each do |ngram|
          counts[ngram] += 1
        end
      end

      # turn counts into inverse frequencies
      @freq = Hash.new(1)
      total = counts.values.inject(&:+).to_f
      counts.each do |ngram, count|
        @freq[ngram] = ((total / count) * 10).round
      end
    end

    # The current haystack.
    def haystack
      @haystack
    end

    # Match each item in +needles+ to an item in #haystack. Returns an
    # array of tuples, <tt>[needle, haystack, score]</tt>. Scores
    # range from 0 to 1, with 1 being a perfect match and 0 being a
    # terrible match.
    def matches(needles)
      if haystack.nil?
        raise RuntimeError.new('can\'t match before setting a haystack')
      end

      # create Elements
      needles = import_list(needles)

      # get candidate matches
      candidates = candidates_for(needles)
      vputs " got #{candidates.length} candidates."

      # pick winners
      winners(needles, candidates)
    end

    # Turn an opaque item from the user into a string.
    def read(opaque)
      if reader
        return reader.call(opaque)
      end

      if opaque.is_a?(String)
        return opaque
      end
      raise "can't turn #{opaque.inspect} into string"
    end

    # Normalize an incoming string from the user.
    def normalize(incoming_str)
      if normalizer
        return normalizer.call(incoming_str)
      end

      str = incoming_str
      str = str.downcase
      str = str.gsub(/[^a-z0-9]/, " ")
      # squish whitespace
      str = str.gsub(/\s+/, " ").strip
      str
    end

    # Generate ngrams from a normalized str.
    def ngrams(str)
      if ngrammer
        return ngrammer.call(str)
      end

      # two letter ngrams (bigrams)
      ngrams = str.each_char.each_cons(2).map(&:join)
      # runs of digits
      ngrams += str.scan(/\d+/)
      ngrams.uniq
    end

    # Sum up the frequency weights of the +ngrams+.
    def ngrams_sum(ngrams)
      ngrams.map { |i| @freq[i] }.inject(&:+) || 0
    end

    # Calculate the frequency weighted
    # simhash[http://matpalm.com/resemblance/simhash/] of the
    # +ngrams+.
    def simhash(ngrams)
      # map each ngram to its bitsums
      sums = ngrams.map { |i| simhash_bitsums(i) }
      # transpose and calculate final sum for each bit
      bits = sums.transpose.map { |values| values.inject(&:+) }
      # wherever we have a positive sum, the simhash bit is 1
      simhash = 0
      bits.each_with_index do |i, index|
        simhash |= (1 << index) if i > 0
      end
      simhash
    end

    def inspect #:nodoc:
      "Matcher"
    end

    protected

    # Turn a list of user supplied opaque items into a list of
    # Elements (if necessary).
    def import_list(list)
      if !list.first.is_a?(Element)
        list = list.map { |opaque| element_for(opaque) }
      end
      list
    end

    # Turn a user's opaque item into an Element.
    def element_for(opaque)
      Element.new(self, opaque)
    end

    def bk_tree
      @bk_tree ||= begin
        # calculate this first so we get a nice progress bar
        veach(" simhash", haystack) { |i| i.simhash }

        # build the bk tree
        tree = BK::Tree.new(lambda { |a, b| Bits.hamming32(a.simhash, b.simhash) })
        veach(" bktree", haystack) { |i| tree.add(i) }
        tree
      end
    end

    # calculate the simhash bitsums for this +ngram+, as part of
    # calculating the simhash. We can cache this because it only
    # depends on the freq and ngram.
    def simhash_bitsums(ngram)
      @bitsums[ngram] ||= begin
        # hash the ngram using a consistent hash (ruby's hash changes
        # across sessions)
        hash = Digest::MD5.hexdigest(ngram).to_i(16)

        # map hash bits, 1 ? f : -f
        f = freq[ngram]
        array = Array.new(32, 0)
        (0...32).each do |i|
          array[i] = (((hash >> i) & 1) == 1) ? f : -f
        end
        array
      end
    end

    # Puts if +verbose+ is true
    def vputs(s)
      $stderr.puts s if verbose
    end

    # Like each, but with a progress bar if +verbose+ is true
    def veach(title, array, &block)
      if !verbose
        array.each do |i|
          yield(i)
        end
      else
        begin
          pb = ProgressBar.new(title, array.length)
          array.each do |i|
            yield(i)
            pb.inc
          end
        ensure
          pb.finish
        end
      end
    end
  end
end
