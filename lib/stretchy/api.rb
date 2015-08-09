module Stretchy
  class API

    DEFAULT_BOOST     = 2.0
    DEFAULT_PER_PAGE  = 10

    extend Forwardable
    delegate [:json] => :collector

    attr_reader :collector, :root, :context

    def initialize(options = {})
      @collector  = Collector.new(options[:nodes] || [])
      @root       = options[:root]     || {}
      @context    = options[:context]  || {}
    end

    def limit(size)
      @root[:size] = size
      self
    end
    alias :size :limit

    def offset(from)
      @root[:from] = from
      self
    end
    alias :from :offset

    def page(num, options = {})
      size = options[:per_page] || @root[:from] || DEFAULT_PER_PAGE
      from = ([num.to_i, 1].max - 1) * size
      from += 1 unless from == 0
      @root[:from] = from
      @root[:size] = size
      self
    end

    def context?(*args)
      (args - context.keys).empty?
    end

    def explain
      @root[:explain] = true
      self
    end

    def where(params = {})
      add_context(:where, :filter)
      return self unless params.any?

      add_nodes Factory.where_nodes(params, context)
    end

    def match(params = {})
      add_context(:match, :query)
      return self unless params.any?

      add_nodes Factory.match_nodes(params, context)
    end

    def query(params = {})
      add_context(:query)
      return self unless params.any?

      add_nodes Factory.raw_node(params, context)
    end

    def filter(params = {})
      add_context(:filter)
      return self unless params.any?

      add_nodes Factory.raw_node(params, context)
    end

    def boost(params = {})
      add_context(:boost)
      return self unless params.any?

      add_nodes Factory.raw_node(params, context)
    end

    def field_value(params = {})
      add_context(boost: :raw)

      add_nodes Factory.field_value_function_node(params, context)
    end

    def random(seed)
      add_context(boost: :raw)

      add_nodes Factory.random_score_function_node(seed, context)
    end

    def near(params = {})
      add_context(boost: :raw)

      add_nodes Factory.decay_function_node(params, context)
    end

    def should(params = {})
      add_context(:should)
      return self unless params.any?

      if context?(:query)
        add_nodes Factory.match_nodes(params, context)
      else
        add_nodes Factory.where_nodes(params, context)
      end
    end

    def not(params = {})
      add_context(:must_not)
      return self unless params.any?

      if context?(:query) || context?(:match)
        add_nodes Factory.match_nodes(params, context)
      else
        add_nodes Factory.where_nodes(params, context)
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

    def scores
      @scores ||= Hash[results.map {|r| [coerce_id(r['_id']), r['_score']]}]
    end

    def explanations
      @explanations ||= Hash[results.map {|r|
        [coerce_id(r['_id']), r['_explanation']]
      }]
    end

    private

      def coerce_id(id)
        id =~ /\d+/ ? id.to_i : id
      end

      def add_nodes(additional)
        self.class.new nodes: collector.nodes + Array(additional), root: root
      end

      def add_context(*args)
        to_merge = args.reduce({}) do |ctx, item|
          item.is_a?(Hash) ? ctx.merge(item) : ctx.merge({item => true})
        end
        @context = context.merge(to_merge)
        self
      end

  end
end
