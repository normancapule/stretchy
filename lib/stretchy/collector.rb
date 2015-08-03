module Stretchy
  class Collector

    extend Forwardable
    delegate [:<<, :each] => :nodes
    delegate [:json] => :node

    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    def node
      if any_nodes?(:boost)
        function_score_node
      elsif any_nodes?(:filter)
        filtered_query_node
      else
        query_node
      end
    end

    def select_nodes(context, s_nodes = nodes)
      s_nodes.select {|n| n.context?(context) }
    end

    def any_nodes?(context, s_nodes = nodes)
      s_nodes.any? {|n| n.context?(context) }
    end

    def bool_or_first(b_nodes)
      if b_nodes.length > 1             ||
         any_nodes?(:must_not, b_nodes) ||
         any_nodes?(:should, b_nodes)

        Factory.bool_node(b_nodes)
      else
        b_nodes.first
      end
    end

    def query_nodes
      select_nodes(:query).reject do |n|
        n.context?(:filter) || n.context?(:where) || n.context?(:boost)
      end
    end

    def filter_nodes
      select_nodes(:filter).reject do |n|
        n.context?(:boost)
      end
    end

    def query_node
      bool_or_first(query_nodes)
    end

    def filter_node
      bool_or_first(filter_nodes)
    end

    def filtered_query_node
      options = {}
      options[:query] = query_node   if query_nodes.any?
      options[:filter] = filter_node if filter_nodes.any?
      Factory.filtered_query_node(options)
    end

    def function_score_node
      options = {functions: select_nodes(:boost)}
      if query_nodes.any? && filter_nodes.any?
        options[:query]  = filtered_query_node
      elsif filter_nodes.any?
        options[:filter] = filter_node
      elsif query_nodes.any?
        options[:query]  = query_node
      else
        options[:query]
      end

      Factory.function_score_query_node(options)
    end

  end
end
