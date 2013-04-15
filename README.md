# Welcome to simhilarity

Simhilarity is a small gem for quickly matching up text strings that are similar but not identical. It's fast for small datasets. On my lowly machine it takes 1.2s to match 40 strings against 2500 potential matches.

Measured against a known dataset for my use case, it comes up with the right match around 97% of the time.

Here's how it works:

1. Normalize strings. Downcase, remove non-alpha, etc. For example:

   ```ruby
   normalize("Hello,  WORLD!") => "hello world"
   ```
1. Calculate [ngrams](http://en.wikipedia.org/wiki/N-gram) from strings. Specifically, it creates bigrams (2 character ngrams) and also creates an ngram for each sequence of digits in the string. For example:

   ```ruby
                        # bigrams                        # digits
   ngrams("hi 123") => ["hi", "i ", " 1", "12", "23"] + ["123"]
   ```
1. Calculate frequency of ngrams in the corpus.
1. Score pairs of strings by measuring ngram overlap (with frequency weighting), using the [dice coefficient](http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient).
1. For each input string, return the match with the highest score.

Here's output from a sample run:

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
$ simhilarity needle.txt haystack.txt

simhilarity finished in 1.221s.

score,needle,haystack
0.900,1 Quail Street,1 Quail
1.000,103 Oceanwood,103 Oceanwood
...
```

It will print out the best matches between needle and haystack in CSV format.

### Simhilarity::Bulk

To use simhilarity from code, create a `Bulk` and call `matches(needle, haystack)`. It'll return an array of tuples, `[score, needle, haystack]`. By default, simhilarity assumes that needle and haystack are arrays of strings. To use something else, set `reader` to a proc that converts your opaque objects into strings. See **Options**, below.

### Simhilarity::Single

Sometimes it's useful to just calculate the score between two strings. For example, if you just want a title similarity measurement as part of some larger analysis between two books. Create a `Single` and call `score(a, b)` to measure similarity between those two items. By default, simhilarity assumes that needle and haystack are arrays of strings. To use something else, set `reader` to a proc that converts your opaque objects into strings. See **Options**, below.

Important note: For best results with `Single`, set the corpus so that simhilarity can calculate ngram frequencies. This can dramatically improve accuracy. `Bulk` will do this automatically because it has access to the corpus, but `Single` doesn't. Call `corpus=` manually when using `Single`.

## Options

There are three major ways to customize simhilarity:

* **reader** - proc for converting your opaque objects into strings. Set this to use something other than strings for source data. For example, if you want to match author names between ActiveRecord book objects:

   ```ruby
   matcher.reader = lambda { |i| i.author }
   matcher.matches(needle, haystack)
   ```

* **normalizer** - proc for normalizing incoming strings. The default normalizer downcases, removes non-alphas, and strips whitespace.

* **ngrammer** - proc for converting normalized strings into ngrams. The default ngrammer pulls out bigrams and runs of digits, which is perfect for matching names and addresses.

## Limitations

* Matching is O(n^2), since simhilarity calculates scores for every pair. This won't scale very well if needle and haystack are both large. For large datasets you should probably use [simhash](http://matpalm.com/resemblance/simhash/) instead of this gem.
* Actually, simhilarity doesn't examine every pair. It only looks at pairs that overlap by three or more ngrams. This speeds things up, but can trip you up with edge cases that overlap poorly!
