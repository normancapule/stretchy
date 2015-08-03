module Stretchy
  class API

    DEFAULT_BOOST = 2.0

    extend Forwardable
    delegate [:json] => :collector

    attr_reader :collector, :root, :context

    def initialize(options = {})
      @collector  = Collector.new(options[:nodes] || [])
      @root       = options[:root]     || {}
      @context    = options[:context]  || Set.new
    end

    def context?(kind)
      context.include?(kind)
    end

    def explain
      @root[:explain] = true
      self
    end

    def where(params = {})
      return add_context(:where, :filter) unless params.any?
      @context += [:where, :filter]
      if context?(:boost)
        add_nodes boost_filters(params)
      else
        add_nodes Factory.where_nodes(params, context)
      end
    end

    def match(params = {})
      return add_context(:match, :query) unless params.any?
      @context += [:match, :query]
      if context?(:boost)
        add_nodes boost_match_filters(params)
      elsif context?(:where) || context?(:filter)
        add_nodes match_filters(params)
      else
        add_nodes Factory.match_nodes(params, context)
      end
    end

    def query(params = {})
      return add_context(:query) unless params.any?
      @context << :query
      if context?(:where) || context?(:filter)
        add_nodes Factory.query_filter_node(
          Factory.raw_node(params, context), context
        )
      else
        add_nodes Factory.raw_node(params, context)
      end
    end

    def filter(params = {})
      return add_context(:filter) unless params.any?
      add_nodes Factory.raw_node(params, context + [:filter])
    end

    def boost(params = {})
      return add_context(:boost) unless params.any?
      add_nodes Factory.raw_node(params, context + [:function])
    end

    def field_value(params = {})
      @context << :boost
      add_nodes Factory.field_value_function_node(params, context)
    end

    def random(seed)
      @context << :boost
      add_nodes Factory.random_score_function_node(seed, context)
    end

    def near(params = {})
      @context << :boost
      add_nodes Factory.decay_function_node(params, context)
    end

    def should(params = {})
      return add_context(:should) unless params.any?
      @context << :should
      if context?(:query)
        add_nodes Factory.match_nodes(params, context)
      else
        add_nodes Factory.where_nodes(params, context)
      end
    end

    def not(params = {})
      return add_context(:must_not) unless params.any?
      @context << :must_not
      if context?(:query) || context?(:match)
        match params
      else
        where params
      end
    end

    def request
      @request ||= root.merge(body: {query: json})
    end

    def response
      @response ||= Stretchy.search(request)
    end

    def results
      @results ||= response['hits']['hits'].map do |r|
        fields = r.reject {|k, _| k == '_source'}
        fields['_id'] = coerce_id(fields['_id']) if fields['_id']
        r['_source'].merge(fields)
      end
    end

    def ids
      @ids ||= response['hits']['hits'].map {|r| coerce_id r['_id'] }
    end

    private

      def coerce_id(id)
        id =~ /\d+/ ? id.to_i : id
      end

      def add_nodes(additional)
        self.class.new nodes: collector.nodes + Array(additional), root: root
      end

      def add_context(*args)
        @context += args
        self
      end

      def context?(*args)
        args.all? {|c| context.include?(c) }
      end

      def wrap_must_not(nodes)
        nodes.map do |n|
          next n unless n.context?(:filter) || n.context?(:where)
          next n unless n.context?(:must_not)
          Factory.not_filter_node(n, n.context)
        end
      end

      def match_filters(params = {})
        Factory.match_nodes(params, context).map do |n|
          Factory.query_filter_node(n, n.context + [:filter])
        end
      end

      def boost_filters(params = {})
        options = {}
        options[:weight] = params.delete(:weight) || DEFAULT_BOOST
        boost_nodes = wrap_must_not Factory.where_nodes(params, context)
        Factory.filter_function_nodes(
          boost_nodes, options, context
        )
      end

      def boost_match_filters(params = {})
        options = {}
        options[:weight] = params.delete(:weight) || DEFAULT_BOOST
        boost_nodes = wrap_must_not match_filters(params)
        Factory.filter_function_nodes(
          boost_nodes, options, context
        )
      end

  end
end
