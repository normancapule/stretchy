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
      elsif filter_nodes.any?
        filtered_query_node
      elsif query_nodes.any?
        single_query_node
      else
        Node.new({match_all: {}}, context)
      end
    end

    def query_nodes
      @query_nodes ||= collect_nodes nodes do |n|
        n.context?(:query)  &&
        !n.context?(:boost) &&
        !n.context?(:filter)
      end
    end

    def filter_json
      filter_node.json
    end

    def filter_node
      @filter_node ||= if query_nodes.any? || boost_nodes.any?
        Node.new({query: filtered_query_node.json}, context)
      else
        fn = Node.new(compile_nodes(filter_nodes).json, context)
      end
    end

    def filter_nodes
      @filter_nodes ||= begin
        node_arr = collect_nodes nodes do |n|
          n.context?(:filter) &&
          !n.context?(:query) &&
          !n.context?(:boost)
        end
        node_arr += Array(compile_query_filter_node)
        node_arr.compact
      end
    end

    def query_filter_nodes
      @query_filter_nodes ||= collect_nodes nodes do |n|
        n.context?(:filter) &&
        n.context?(:query)  &&
        !n.context?(:boost)
      end
    end

    def boost_nodes
      @boost_nodes ||= collect_nodes nodes do |n|
        n.context?(:boost)
      end
    end

    private

      def collect_nodes(node_arr)
        coll = []
        node_arr.each do |n|
          next unless yield(n)

          if n.respond_to? :node
            coll << Node.new(n.node.json, n.context)
          else
            coll << n
          end
        end
        coll.compact
      end

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

      def compile_query_filter_node
        compiled = compile_nodes(query_filter_nodes)
        Node.new(query: compiled.json) if compiled
      end

      def function_score_node
        function_score_json = compile_function_score_options
        function_score_json[:functions] = compile_boost_functions

        if query_nodes.any?
          function_score_json[:query]   = filtered_query_node.json
        elsif filter_nodes.any?
          function_score_json[:filter]  = filter_node.json
        end

        Node.new({function_score: function_score_json}, context)
      end

      def filtered_query_node
        filtered_json = {}
        q = compile_nodes(query_nodes)
        f = compile_nodes(filter_nodes)
        filtered_json[:query]   = q.json  if q
        filtered_json[:filter]  = f.json  if f
        Node.new({filtered: filtered_json}, context)
      end

      def single_query_node
        Node.new(compile_nodes(query_nodes).json, context)
      end

  end
end
