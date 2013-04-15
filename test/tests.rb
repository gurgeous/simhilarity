require "awesome_print"
require "benchmark"
require "csv"
require "ostruct"
require "simhilarity"
require "test/unit"

class Tests < Test::Unit::TestCase
  def setup
    @matcher = Simhilarity::Matcher.new
  end

  # Read the sample.csv test data file. needle is a list of needle
  # strings, haystack is a list of haystack strings, and matches is a
  # hash mapping from needle to haystack for known good matches.
  def sample
    sample = OpenStruct.new(needle: [], haystack: [], matches: { })
    CSV.read(File.expand_path("../sample.csv", __FILE__)).each do |cols|
      n, h = *cols
      sample.needle << n if n
      sample.haystack << h if h
      sample.matches[n] = h if n && h
    end
    sample
  end

  #
  # procs
  #

  def test_read
    # default
    assert_equal @matcher.read("gub"), "gub"

    # not a string
    assert_raise(RuntimeError) { @matcher.read(123) }

    # custom
    @matcher.reader = lambda(&:key)
    assert_equal @matcher.read(OpenStruct.new(key: "gub")), "gub"
  end

  def test_normalizer
    # default
    assert_equal @matcher.normalize(" HELLO,\tWORLD! "), "hello world"

    # custom
    @matcher.normalizer = lambda(&:upcase)
    assert_equal @matcher.normalize("gub"), "GUB"
  end

  def test_ngrams
    # default
    assert_equal @matcher.ngrams("hi 42"), ["hi", "i ", " 4", "42"]

    # custom
    @matcher.ngrammer = lambda(&:split)
    assert_equal @matcher.ngrams("hi 42"), ["hi", "42"]
  end

  def test_proc_options
    matcher = Simhilarity::Matcher.new(reader: lambda(&:key), normalizer: lambda(&:upcase), ngrammer: lambda(&:split))
    assert_equal matcher.read(OpenStruct.new(key: "gub")), "gub"
    assert_equal matcher.normalize("gub"), "GUB"
    assert_equal matcher.ngrams("hi 42"), ["hi", "42"]
  end

  def test_single
    score = Simhilarity::Single.new.score("hello world", "hi worlds")
    assert (score - 0.556).abs < 0.001
  end

  def test_bulk
    sample = self.sample

    # match, with benchmark
    output = nil
    Benchmark.bm do |bm|
      bm.report "match" do
        output = Simhilarity::Bulk.new.matches(sample.needle, sample.haystack)
      end
    end

    # what percent of matches are correct?
    correct = output.select { |n, h, score| sample.matches[n] == h }
    correct = correct.length.to_f / sample.needle.length
    assert (correct - 0.974).abs < 0.001
  end
end
