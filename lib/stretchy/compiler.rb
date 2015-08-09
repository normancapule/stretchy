module Stretchy
  class Compiler

    extend Forwardable
    delegate [:json] => :node
    delegate [:each] => :nodes
    include Enumerable

    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    def node
      if boost_nodes.any?
        function_score_node
      elsif filter_nodes.any?
        filtered_query_node
      elsif query_nodes.any?
        query_node
      else
        Factory.match_all_node
      end
    end

    private

      def select_nodes(context, s_nodes = nodes)
        s_nodes.select {|n| n.context?(context) }
      end

      def any_nodes?(context, s_nodes = nodes)
        s_nodes.any? {|n| n.context?(context) }
      end

      # select nodes to go in the "query:" section
      # not in filtered query or boost
      def query_nodes
        @query_nodes ||= select_nodes(:query).map do |n|
          next if n.context?(:filter) || n.context?(:where) || n.context?(:boost)
          n
        end.compact
      end

      # select nodes to go in the "filter:" section
      # not in boost
      def filter_nodes
        @filter_nodes ||= select_nodes(:filter).map do |n|
          next if n.context?(:boost)
          Factory.filter_node(n)
        end.compact
      end

      # select all boost nodes
      def boost_nodes
        @boost_nodes ||= select_nodes(:boost).map do |n|
          Factory.function_node(n)
        end
      end

      # given list of nodes, choose whether to
      # use a bool node or just the first in the set
      def bool_or_first(b_nodes)
        if b_nodes.length > 1             ||
           any_nodes?(:must_not, b_nodes) ||
           any_nodes?(:should, b_nodes)

          Factory.bool_node(b_nodes)
        else
          b_nodes.first
        end
      end

      # compile query nodes into bool query or single query
      def query_node
        @query_node ||= bool_or_first(query_nodes)
      end

      # compile filter nodes into bool filter or single filter
      def filter_node
        @filter_node ||= bool_or_first(filter_nodes)
      end

      # combine query and filter nodes into query: filtered:
      def filtered_query_node
        return @filtered_query_node if @filtered_query_node
        options = {}
        options[:query]      = query_node  if query_nodes.any?
        options[:filter]     = filter_node if filter_nodes.any?
        @filtered_query_node = Factory.filtered_query_node(options)
      end

      # combine filtered query and boosts into function score
      def function_score_node
        return @function_score_node if @function_score_node
        options = {functions: boost_nodes}

        if query_nodes.any? && filter_nodes.any?
          options[:query]  = filtered_query_node
        elsif filter_nodes.any?
          options[:filter] = filter_node
        elsif query_nodes.any?
          options[:query]  = query_node
        end

        @function_score_node = Factory.function_score_query_node(options)
      end

  end
end
