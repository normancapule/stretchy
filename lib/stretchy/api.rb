require 'stretchy/utils'

module Stretchy
  class API
    DEFAULT_BOOST     = 2.0
    DEFAULT_PER_PAGE  = 10

    extend  Forwardable
    include Utils::Methods

    delegate [:total, :ids, :scores, :explanations, :results,
              :aggregations] => :results

    attr_reader :collector, :root, :context

    def initialize(options = {})
      @collector  = AndCollector.new(options[:nodes] || [], query: true)
      @root       = options[:root]     || {}
      @context    = options[:context]  || {}
    end

    def context?(*args)
      (args - context.keys).empty?
    end

    def limit(size = nil)
      return @root[:size] || DEFAULT_PER_PAGE unless size
      @root[:size] = size.to_i
      self
    end
    alias :limit_value :limit

    def offset(from = nil)
      return @root[:from] || 0 unless from
      @root[:from] = from.to_i
      self
    end

    # page 1 = from: 0, size: per_page
    # page 2 = from: per_page, size: per_page
    def page(num = nil, params = {})
      return current_page if num.nil?
      per_page = params[:limit] || params[:per_page] || limit
      per_page = per_page.to_i > 0 ? per_page : 1
      start    = [num.to_i - 1, 0].max
      @root[:size] = per_page
      @root[:from] = start * per_page
      self
    end

    def current_page
      current = [offset, 1].max
      current > 1 ? (offset / limit).ceil + 1 : current
    end

    def explain
      @root[:explain] = true
      self
    end

    def aggs(params = {})
      @root[:aggs] = params
      self
    end

    def where(params = {})
      add_params params, :filter, :context_nodes
    end

    def range(params = {})
      require_context!
      add_nodes Factory.range_node(params, context)
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

    def should(params = {})
      add_params params, :should, :context_nodes
    end

    def not(params = {})
      add_params params, :must_not, :context_nodes
    end

    def range(params = {})
      add_params params, context, :range_node
    end

    def boost(params = {}, options = {})
      add_context :boost
      return self unless params.any?

      if params.is_a? self.class
        boost_json = options.merge(filter: params.filter_node.json)
        add_nodes Node.new(boost_json, context)
      else
        add_nodes Factory.raw_boost_node(params, context)
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

    def request
      @request ||= begin
        aggregates = root.delete(:aggs) || {}
        root.merge(body: {query: collector.as_json, aggs: aggregates})
      end
    end

    def response
      @response ||= Stretchy.search(request)
    end

    def results
      @results ||= Results.new request, response
    end

    def method_missing(method, *args, &block)
      if collector.respond_to?(method)
        collector.send(method, *args, &block)
      else
        super
      end
    end

    private

      def require_context!
        return true if context?(:query) || context?(:filter)
        raise 'You must specify either query or filter context'
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
