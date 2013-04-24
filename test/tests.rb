require "awesome_print"
require "benchmark"
require "csv"
require "ostruct"
require "simhilarity"
require "test/unit"

class Tests < Test::Unit::TestCase
  #
  # helpers
  #

  def setup
    Dir.chdir(File.expand_path("../", __FILE__))
    @matcher = Simhilarity::Matcher.new
  end

  # Read the sample.csv test data file. needle is a list of needle
  # strings, haystack is a list of haystack strings, and matches is a
  # hash mapping from needle to haystack for known good matches.
  def sample
    sample = OpenStruct.new(needle: [], haystack: [], matches: { })
    CSV.read("sample.csv").each do |cols|
      n, h = *cols
      sample.needle << n if n
      sample.haystack << h if h
      sample.matches[n] = h if n && h
    end
    sample
  end

  def assert_candidates(candidates, percent)
    sample = self.sample

    # match, with benchmark
    output = nil
    Benchmark.bm(10) do |bm|
      bm.report(candidates.to_s) do
        matcher = Simhilarity::Matcher.new(candidates: candidates)
        matcher.corpus = sample.haystack
        output = matcher.matches(sample.needle)
      end
    end

    # what percent of matches are correct?
    correct = output.select { |n, h, score| sample.matches[n] == h }
    correct = correct.length.to_f / sample.needle.length

    # for debugging
    # printf("%% correct: %.3f\n", correct)
    # output.each do |n, h, score|
    #   good = sample.matches[n] == h
    #   printf("%2s %4.2f %-35s %-35s\n", good ? "" : "xx", score || 0, n, h)
    # end

    assert((correct - percent).abs < 0.001, "percent #{correct} != #{percent}")
  end

  def assert_system(cmd)
    system("#{cmd} > /dev/null 2>&1")
    assert($? == 0, "#{cmd} failed")
  end

  #
  # tests
  #

  def test_read
    # default
    assert_equal @matcher.read("gub"), "gub"

    # not a string
    assert_raise(RuntimeError) { @matcher.read(123) }

    matcher = Simhilarity::Matcher.new(reader: lambda(&:key))
    assert_equal matcher.read(OpenStruct.new(key: "gub")), "gub"
  end

  def test_normalizer
    # default
    assert_equal @matcher.normalize(" HELLO,\tWORLD! "), "hello world"

    # custom
    matcher = Simhilarity::Matcher.new(normalizer: lambda(&:upcase))
    assert_equal matcher.normalize("gub"), "GUB"
  end

  def test_ngrams
    # default
    assert_equal @matcher.ngrams("hi 42"), ["hi", "i ", " 4", "42"]

    # custom
    matcher = Simhilarity::Matcher.new(ngrammer: lambda(&:split))
    assert_equal matcher.ngrams("hi 42"), ["hi", "42"]
  end

  def test_proc_options
    matcher = Simhilarity::Matcher.new(reader: lambda(&:key), normalizer: lambda(&:upcase), ngrammer: lambda(&:split))
    assert_equal matcher.read(OpenStruct.new(key: "gub")), "gub"
    assert_equal matcher.normalize("gub"), "GUB"
    assert_equal matcher.ngrams("hi 42"), ["hi", "42"]
  end

  def test_no_selfdups
    # if you pass in the same list twice, it should ignore self-dups
    list = ["hello, world", "hello there"]
    @matcher.corpus = list
    matches = @matcher.matches(@matcher.corpus)
    assert_not_equal matches[0][1], "hello, world"
  end

  def test_corpus_required
    # if you do not set a corpus, the matcher should yell
    matcher = Simhilarity::Matcher.new
    assert_raise RuntimeError do
      matches = matcher.matches(['FOOM'])
    end
  end

  def test_bin
    bin = "../bin/simhilarity"
    assert_system("#{bin} identity.txt identity.txt")
    assert_system("#{bin} -v identity.txt identity.txt")
    assert_system("#{bin} --candidates simhash identity.txt identity.txt")
    assert_system("#{bin} --candidates simhash=3 identity.txt identity.txt")
    assert_system("#{bin} --candidates ngrams identity.txt identity.txt")
    assert_system("#{bin} --candidates ngrams=3 identity.txt identity.txt")
    assert_system("#{bin} --candidates all identity.txt identity.txt")
  end

  def test_candidates
    assert_candidates(:all, 0.949)
    assert_candidates(:ngrams, 0.949)
    assert_candidates(:simhash, 0.949)
  end
end
