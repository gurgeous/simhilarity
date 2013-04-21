module Simhilarity
  module Score
    # walk candidates by score, pick winners
    def winners(needles, candidates)
      # calculate this first so we get a nice progress bar
      veach("Scoring", candidates) do |i|
        i.score = score(i)
      end

      # sort by score
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

    # Score a +Candidate+. The default implementation is the {dice
    # coefficient}[http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient],
    # <tt>(2*c)/(a+b)</tt>.
    #
    # * +a+: the frequency weighted sum of the ngrams in a
    # * +b+: the frequency weighted sum of the ngrams in b
    # * +c+: the frequency weighted sum of the ngrams in (a & b)
    def score(candidate)
      if options[:scorer]
        return options[:scorer].call(candidate)
      end

      c = (candidate.a.ngrams & candidate.b.ngrams)
      return 0 if c.length == 0

      a = candidate.a.ngrams_sum
      b = candidate.b.ngrams_sum
      c = ngrams_sum(c)
      (2.0 * c) / (a + b)
    end
  end
end
