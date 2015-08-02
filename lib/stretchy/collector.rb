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
      if any_nodes?(:function)
        function_score_node
      elsif any_nodes?(:filter)
        filtered_query_node
      else
        query_node
      end
    end

    def select_nodes(context, s_nodes = nodes)
      s_nodes.select {|n| n.context.include?(context) }
    end

    def any_nodes?(context, s_nodes = nodes)
      s_nodes.any? {|n| n.context.include?(context) }
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

    def query_node
      bool_or_first(
        select_nodes(:query).reject{|n| n.context.include?(:filter)}
      )
    end

    def filter_node
      bool_or_first(select_nodes(:filter))
    end

    def filtered_query_node
      Factory.filtered_query_node(
        query:  query_node,
        filter: filter_node
      )
    end

    def function_score_node
      options = {functions: select_nodes(:function)}
      if any_nodes?(:filter) && any_nodes?(:query)
        options[:query]  = filtered_query_node
      elsif any_nodes?(:filter)
        options[:filter] = filter_node
      else
        options[:query]  = bool_or_first(select_nodes(:query))
      end

      Factory.function_score_query_node(options)
    end

  end
end
