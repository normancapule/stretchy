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

    def with_context(new_context)
      self.class.new nodes, new_context
    end

    def context?(*args)
      args.all? {|c| !!context[c] }
    end

    def node
      @node ||= if boost_nodes.any?
        function_score_node
      elsif query_nodes.size > 1
        filtered_query_node
      elsif query_nodes.any?
        single_query_node
      else
        Node.new({match_all: {}}, context)
      end
    end

    def query_nodes
      @query_nodes ||= nodes.reject {|n| n.context? :boost }
    end

    def boost_nodes
      @boost_nodes ||= nodes.select {|n| n.context? :boost }
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

      def compile_boost_functions
        boost_nodes.map do |n|
          next unless n.json.any?
          n.json
        end.compact
      end

      def compile_function_score_options
        boost_nodes.reduce({}) do |options, node|
          options.merge(node.context[:fn_score] || {})
        end
      end

      def function_score_node
        function_score_json = compile_function_score_options
        function_score_json[:functions] = compile_boost_functions

        if query_nodes.any?
          function_score_json[:query] = filtered_query_node.json
        end

        Node.new({function_score: function_score_json}, context)
      end

      def filtered_query_node
        filtered_json = {}
        q = compile_nodes(query_nodes)
        filtered_json[:query]   = q.json  if q
        Node.new({filtered: filtered_json}, context)
      end

      def single_query_node
        Node.new(compile_nodes(query_nodes).json, context)
      end

  end
end
