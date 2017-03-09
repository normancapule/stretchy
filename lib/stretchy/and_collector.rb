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
      @node ||= if function_score_node?
        function_score_node
      elsif query_nodes.any?
        query_node
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

    def function_score_node?
      boost_nodes.reject { |n| n.empty? }.any?
    end

    private

      def query_node
        if query_nodes.size > 1 || multicontext?(query_nodes)
          compile_bool query_nodes
        else
          query_nodes.first
        end
      end

      def multicontext?(node_arr)
        Array(node_arr).any? {|n| n.context?(:must_not) || n.context?(:should) }
      end

      def compile_bool(bool_nodes)
        split_nodes = split_nodes_for_bool(bool_nodes)
        refined = bool_ctx.each_with_object(split_nodes) do |k, hash|
          hash[k] = Array(compile_bool(hash[k])) if multicontext? hash[k]
        end
        bool_json = Hash[refined.map{|k,v| [k, v.map(&:as_json)] }]
        Node.new(bool: bool_json)
      end

      def bool_ctx
        [:filter, :must_not, :should]
      end

      def split_nodes_for_bool(bool_nodes)
        bool_nodes.each_with_object({}) do |n, hash|
          key = bool_ctx.find{|c| n.context? c } || :must
          hash[key] ||= []
          hash[key] << Node.new(n.json, n.context.merge(key => nil))
        end
      end

      def compile_boost_functions
        boost_nodes.map do |n|
          next if n.empty?
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
        function_score_json[:query] = query_node.json if query_nodes.any?

        Node.new({function_score: function_score_json}, context)
      end

  end
end
