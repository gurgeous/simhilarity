require "progressbar"

module Simhilarity
  # Abstract superclass for matching. Mainly a container for options, corpus, etc.
  class Matcher
    # Options used to create this Matcher.
    attr_accessor :options

    # Proc for turning needle/haystack elements into strings. You can
    # leave this nil if the elements are already strings. See
    # Matcher#reader for the default implementation.
    attr_accessor :reader

    # Proc for normalizing input strings. See Matcher#normalize
    # for the default implementation.
    attr_accessor :normalizer

    # Proc for generating ngrams from a normalized string. See
    # Matcher#ngrams for the default implementation.
    attr_accessor :ngrammer

    # Ngram frequency weights from the corpus, or 1 if the ngram isn't
    # in the corpus.
    attr_accessor :freq

    # Create a new Matcher matcher. Options include:
    #
    # * +reader+: Proc for turning opaque items into strings.
    # * +normalizer+: Proc for normalizing strings.
    # * +ngrammer+: Proc for generating ngrams.
    # * +verbose+: If true, show progress bars and timing.
    def initialize(options = {})
      @options = options

      # procs
      self.reader = options[:reader]
      self.normalizer = options[:normalizer]
      self.ngrammer = options[:ngrammer]

      self.freq = Hash.new(1)
    end

    # Set the corpus. Calculates ngram frequencies (#freq) for future
    # scoring.
    def corpus=(corpus)
      @corpus = corpus

      # calculate ngram counts for the corpus
      counts = Hash.new(0)
      import_list(corpus).each do |element|
        element.ngrams.each do |ngram|
          counts[ngram] += 1
        end
      end

      # turn counts into inverse frequencies
      self.freq = Hash.new(1)
      total = counts.values.inject(&:+).to_f
      counts.each do |ngram, count|
        self.freq[ngram] = total / count
      end
    end

    # The current corpus.
    def corpus
      @corpus
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
      Bits.simhash32(freq, ngrams)
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

    # Puts if options[:verbose]
    def vputs(s)
      $stderr.puts s if options[:verbose]
    end

    # Like each, but with a progress bar if options[:verbose]
    def veach(array, title, &block)
      if !options[:verbose]
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
