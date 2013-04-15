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

    # Create a new Matcher matcher. Options include:
    #
    # * +:reader+: Proc for turning opaque items into strings.
    # * +:normalizer+: Proc for normalizing strings.
    # * +:ngrammer+: Proc for generating ngrams.
    def initialize(options = {})
      @options = options

      # procs
      self.reader = options[:reader]
      self.normalizer = options[:normalizer]
      self.ngrammer = options[:ngrammer]

      @weights = Hash.new(1)
    end

    # Set the corpus. This calculates ngram weights for future
    # scoring.
    def corpus=(corpus)
      # calculate ngram counts for the corpus
      counts = Hash.new(0)
      import_list(corpus).each do |element|
        element.ngrams.each do |ngram|
          counts[ngram] += 1
        end
      end

      # turn counts into inverse frequencies
      total = counts.values.inject(&:+).to_f
      counts.each do |ngram, count|
        @weights[ngram] = total / count
      end
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
      bigrams = str.each_char.each_cons(2).map(&:join)
      # runs of digits
      digits = str.scan(/\d+/)
      (bigrams + digits).uniq
    end

    # Sum up the weight of the +ngrams+ using @weights.
    def ngrams_sum(ngrams)
      ngrams.map { |i| @weights[i] }.inject(&:+)
    end

    def inspect
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
  end
end
