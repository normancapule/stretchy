module Stretchy
  class Collector

    extend Forwardable
    delegate [:json, :node] => :compiler
    delegate [:each]   => :nodes
    include Enumerable

    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    def compiler
      @compiler ||= Compiler.new(nodes)
    end

  end
end
