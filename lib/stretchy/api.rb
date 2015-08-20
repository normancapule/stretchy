require 'stretchy/utils'

module Stretchy
  class API

    include Utils

    DEFAULT_BOOST     = 2.0
    DEFAULT_PER_PAGE  = 10

    attr_reader :collector, :root, :context

    def initialize(options = {})
      @collector  = AndCollector.new(options[:nodes] || [], query: true)
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
      add_params params, :filter, :context_nodes
    end

    def match(params = {})
      add_params params, :query, :context_nodes
    end

    def query(params = {})
      add_params params, :query, :raw_node
    end

    def filter(params = {})
      add_params params, :filter, :raw_node
    end

    def boost(params = {}, options = {})
      add_context :boost
      return self unless params.any?

      if params.is_a? self.class
        boost_json = options.merge(filter: params.filter_node.json)
        add_nodes Node.new(boost_json, context)
      else
        add_nodes Factory.raw_node(params, context)
      end
    end

    def field_value(params = {})
      add_params params, :boost, :field_value_function_node
    end

    def random(seed)
      add_params seed, :boost, :random_score_function_node
    end

    def near(params = {})
      add_params params, :boost, :decay_function_node
    end

    def should(params = {})
      add_params params, :should, :context_nodes
    end

    def not(params = {})
      add_params params, :must_not, :context_nodes
    end

    def request
      @request ||= root.merge(body: {query: collector.as_json})
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

    def method_missing(method, *args, &block)
      if collector.respond_to?(method)
        collector.send(method, *args, &block)
      else
        super
      end
    end

    private

      def coerce_id(id)
        id =~ /\d+/ ? id.to_i : id
      end

      def add_params(params = {}, new_context, factory_method)
        add_context new_context
        return self if is_empty?(params)

        if params.is_a? self.class
          add_nodes params.with_context(context)
        else
          add_nodes Factory.send(factory_method, params, context)
        end
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
