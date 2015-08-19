module Stretchy
  class AndCollector

    extend Forwardable
    delegate [:json, :as_json] => :node
    delegate [:each] => :nodes
    include Enumerable

    attr_reader :nodes, :context

    def initialize(nodes, context = {})
      @nodes    = nodes
      @context  = context
    end

    def context?(*args)
      args.all? {|c| !!context[c] }
    end

    def node
      @compiled_node ||= if context?(:filter)
        filter_node
      else
        query_node
      end
    end

    def query_node
      @query_node ||= if boost_nodes.any?
        function_score_node
      elsif filter_nodes.any?
        filtered_query_node
      elsif query_nodes.any?
        single_query_node
      else
        Node.new(match_all: {})
      end
    end

    def query_nodes
      @query_nodes ||= nodes.select do |n|
        n.context?(:query)    &&
        !n.context?(:boost)   &&
        !n.context?(:filter)
      end
    end

    def query_json
      query_node.json
    end

    def filter_node
      @filter_node ||= if query_nodes.any? || boost_nodes.any?
        Node.new(query: filtered_query_node.json)
      else
        Node.new(compile_nodes(filter_nodes).json)
      end
    end

    def filter_nodes
      return @filter_nodes if @filter_nodes
      @filter_nodes = nodes.select do |n|
        n.context?(:filter) &&
        !n.context?(:query) &&
        !n.context?(:boost)
      end
      @filter_nodes += Array(compile_query_filter_node)
      @filter_nodes.compact!
      @filter_nodes
    end

    def query_filter_nodes
      @query_filter_nodes ||= nodes.select do |n|
        n.context?(:filter) &&
        n.context?(:query)  &&
        !n.context?(:boost)
      end
    end

    def filter_json
      filter_node.json
    end

    def boost_nodes
      @boost_nodes ||= nodes.select{|n| n.context?(:boost)}
    end

    private

      def compile_nodes(node_arr)
        if node_arr.size > 1 ||
           node_arr.any?{|n| n.context?(:must_not) || n.context?(:should)}

          compile_bool(node_arr)
        else
          node_arr.first
        end
      end

      def compile_bool(bool_nodes)
        split_nodes = split_nodes_for_bool(bool_nodes)
        bool_json = {}
        if split_nodes[:should_not].size > 0
          bool_json[:should] = [
            {
              bool: {
                must:     split_nodes[:should].map(&:as_json),
                must_not: split_nodes[:should_not].map(&:as_json)
              }
            }
          ]
        else
          bool_json[:should] = split_nodes[:should].map(&:as_json)
        end
        bool_json[:must_not] = split_nodes[:must_not].map(&:as_json)
        bool_json[:must]     = split_nodes[:must].map(&:as_json)
        Node.new(bool: bool_json)
      end

      def split_nodes_for_bool(bool_nodes)
        split_nodes = {must: [], must_not: [], should: [], should_not: []}
        bool_nodes.each do |n|
          if n.context?(:should)
            if n.context?(:must_not)
              split_nodes[:should_not] << n
            else
              split_nodes[:should] << n
            end
          else
            if n.context?(:must_not)
              split_nodes[:must_not] << n
            else
              split_nodes[:must] << n
            end
          end
        end
        split_nodes
      end

      def compile_query_filter_node
        compiled = compile_nodes(query_filter_nodes)
        Node.new(query: compiled.json) if compiled
      end

      def function_score_node
        function_score_json = {
          functions: boost_nodes.map(&:json)
        }
        if query_nodes.any?
          function_score_json[:query]   = filtered_query_node.json
        elsif filter_nodes.any?
          function_score_json[:filter]  = filter_node.json
        end

        Node.new(function_score: function_score_json)
      end

      def filtered_query_node
        filtered_json = {}
        q = compile_nodes(query_nodes)
        f = compile_nodes(filter_nodes)
        filtered_json[:query]   = q.json  if q
        filtered_json[:filter]  = f.json  if f
        Node.new(filtered: filtered_json)
      end

      def single_query_node
        Node.new(compile_nodes(query_nodes).json)
      end

  end
end
