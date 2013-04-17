# Welcome to simhilarity

Simhilarity is a gem for quickly matching up text strings that are similar but not identical. Here is how it works:

1. Normalize strings. Downcase, remove non-alpha, etc:

   ```ruby
   normalize("Hello,  WORLD!") => "hello world"
   ```

1. Calculate [ngrams](http://en.wikipedia.org/wiki/N-gram) from strings. Specifically, it creates bigrams (2 character ngrams) and also creates an ngram for each sequence of digits in the string:

   ```ruby
                        # bigrams                        # digits
   ngrams("hi 123") => ["hi", "i ", " 1", "12", "23"] + ["123"]
   ```

1. Calculate frequency of ngrams in the corpus.

1. Select pairs of strings that might be matches. These are called **candidates**, and there are a few different ways they are chosen - see [options](#options). Simhilarity will try to pick the best method based on the size of your data set.

1. Score candidates by measuring ngram overlap (with frequency weighting), using the [dice coefficient](http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient).

1. For each input string, return the match with the highest score.

Here is output from a sample run:

```
score   needle                                      haystack
1.000   Night Heron 19                              Night Heron 19
1.000   103 Oceanwood                               103 Oceanwood
0.987   Sea Crest 1504                              1504 Sea Crest
0.986   Twin Oaks 189                               189 Twin Oaks
0.981   Sea Crest 1205                              1205 Sea Crest
0.980   Sea Crest 2411                              2411 Sea Crest
0.972   Sea Crest 3405                              3405 Sea Crest
0.968   Barrington Arms 504                         504 Barrington Arms
0.964   Windsor Place 503                           503 Windsor Place
0.951   1802 Bluff Villas - Hilton Head Island      1802 Bluff Villas
0.943   3221 Villamare - Hilton Head Island         3221 Villamare
0.941   134 Shorewood - Hilton Head Island          134 Shorewood
0.900   1 Quail Street                              1 Quail
0.894   2 Quail Street                              2 Quail
0.823   Windsor II 2315                             2315 Windsor Place II
0.736   Beachside Tennis 12                         12 Beachside
0.732   16 Piping Plover - Hilton Head Island       16 Piping Plover
0.460   7 Quail                                     7 QUAIL/126 Dune Lane
0.379   11 Battery                                  11 Gunnery
```

Note that the final match has the lowest score, and is incorrect!

## Usage

### simhilarity executable

The gem includes an executable called `simhilarity`. For example:

```
$ simhilarity needles.txt haystack.txt

simhilarity finished in 1.221s.

score,needle,haystack
0.900,1 Quail Street,1 Quail
1.000,103 Oceanwood,103 Oceanwood
...
```

It will print out the best matches between needle and haystack in CSV format. Use `simhilarity --verbose` to look at pretty progress bars while it's running.

### Simhilarity::Bulk

To use simhilarity from code, create a `Bulk` and call `matches(needles, haystack)`. It'll return an array of tuples, `[needle, haystack, score]`. By default, simhilarity assumes that needles and haystack are arrays of strings. To use something else, set `reader` to a proc that converts your opaque objects into strings. See [options](#options).

### Simhilarity::Single

Sometimes it's useful to just calculate the score between two strings. For example, if you just want a title similarity measurement as part of some larger analysis between two books. Create a `Single` and call `score(a, b)` to measure similarity between those two items. By default, simhilarity assumes that needle and haystack are strings. To use something else, set `reader` to a proc that converts your opaque objects into strings. See [options](#options).

Important note: For best results with `Single`, set the corpus so that simhilarity can calculate ngram frequencies. This can dramatically improve accuracy. `Bulk` will do this automatically because it has access to the corpus, but `Single` doesn't. Call `corpus=` manually when using `Single`.

<a name="benchmarks"/>

## Benchmarks

When looking at simhilarity's speed, there are two important aspects to consider:

* **picking candidates** - how long does it take to pick decent candidates out of all the potential string pairs?
* **matching** - once candidates are identified, how long does it take to score them?

Here are some numbers from my i5 3ghz, for a test dataset consisting of 500 needles and 10,000 haystacks.

#### Picking Candidates

There are three different methods for picking candidates - see [options](#options) for a detailed explanation. Simhash runs very quickly and does an excellent job of identifying candidates. Ngrams is slower and returns huge numbers of candidates, slowing down matching. All checks all candidates - it's a pig.

```
method      time   candidates returned
simhash 5   4s     3,500
simhash 6   7s     5,000
simhash 7   9s     10,000
simhash 8   12s    25,000
simhash 9   13s    60,000

ngrams 5    46s    1,000,000
ngrams 4    44s    1,500,000
ngrams 3    40s    2,100,000

all         3.9s   5,000,000
```

#### Matching

Once candidates are identified, the string pairs are scored and
winners are picked out. Scoring is O(n):

```
candidates   time
25,000       1s
60,000       2s
1,000,000    35s
5,000,000    190s
```



<a name="options"/>

## Options

There are a few ways to configure simhilarity:

* **candidates** - controls how candidates are picked from the complete set of all string pairs. We want to avoid looking at all string pairs, because that's quite expensive for large datasets. On the other hand, if we examine too few we might miss some of the best matches. A conundrum. There are three different settings:

  `:all` - all pairs are examined. This is completely braindead and very slow for large datasets.

  `:ngrams` - for each pair of strings, count the number of ngrams they have in common. If the overlap is >= `options[:ngram_overlaps]`, the pair becomes a candidate. The default minimum number of overlaps is 3 - see [benchmarks](#benchmarks) to get a sense for how different values perform.

  `:simhash` - generate a weighted [simhash](http://matpalm.com/resemblance/simhash/) for each string, then iterate the needles and look for "nearby" haystack simhashes using a [bktree](https://github.com/threedaymonk/bktree). Simhashes are compared using the [hamming distance](http://en.wikipedia.org/wiki/Hamming_distance). If the hamming distance between the simhashes <= `options[:simhash_max_hamming]`, the pair becomes a candidate. The default max hamming distance is 7 - see [benchmarks](#benchmarks) to get a sense for how different values perform.

  Simhash works quite well for my test dataset, but there's no reason not to use `:ngrams` or even `:all` for small data sets. In fact, that's what simhilarity does by default - if you use a small dataset it defaults to `:all`, otherwise it uses `:simhash`. Some examples:

  ```ruby
  Simhilarity::Bulk.new  # defaults to :all or :simhash based on size
  Simhilarity::Bulk.new(candidates: :simhash)
  Simhilarity::Bulk.new(candidates: :simhash, simhash_max_hamming: 8)
  Simhilarity::Bulk.new(candidates: :ngrams, ngram_overlaps: 4)
  ```

* **reader** - proc for converting your opaque objects into strings. Set this to use something other than strings for source data. For example, if you want to match author names between ActiveRecord book objects:

   ```ruby
   matcher.reader = lambda { |i| i.author }
   matcher.matches(needles, haystack)
   ```

* **normalizer** - proc for normalizing incoming strings. The default normalizer downcases, removes non-alphas, and strips whitespace.

* **ngrammer** - proc for converting normalized strings into ngrams. The default ngrammer pulls out bigrams and runs of digits, which is perfect for matching names and addresses.

* **verbose** - if true, show progress while simhilarity is working. Great for the impatient.
