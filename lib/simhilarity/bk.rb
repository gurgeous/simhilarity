#
# This is based on the bk gem, but with a few differences:
#
#  - Each node contains an ARRAY of children instead of a HASH. This
#    only works for small distances and we have to avoid negative
#    distances. Works great for trees that use hamming distance.
#
#  - The distancer Proc is stored in the tree, not each Node. This
#    makes it easier to marshal.
#
#  - Supports marshaling.
#
# For my test case, it's 20% faster to build and 40% faster to query.
#

module Simhilarity
  class Bk
    attr_accessor :distancer

    def initialize
      @root = nil
    end

    def add(term)
      if @root
        @root.add(term, @distancer)
      else
        @root = Node.new(term)
      end
    end

    def query(term, threshold)
      collected = { }
      @root.query(term, @distancer, threshold, collected)
      collected
    end

    def empty?
      !@root
    end

    def marshal_dump
      @root
    end

    def marshal_load(object)
      @root = object
    end
  end

  class Node
    def initialize(term)
      @term = term
      @children = []
    end

    def add(term, distancer)
      score = distancer.call(term, @term)
      if child = @children[score]
        child.add(term, distancer)
      else
        @children[score] = Node.new(term)
      end
    end

    def query(term, distancer, threshold, collected)
      distance_at_node = distancer.call(term, @term)
      collected[@term] = distance_at_node if distance_at_node <= threshold

      if @children.length > 0
        min = distance_at_node - threshold
        min = 0 if min < 0
        max = distance_at_node + threshold
        min.upto(max) do |score|
          if child = @children[score]
            child.query(term, distancer, threshold, collected)
          end
        end
      end
    end
  end
end
