module Stretchy
  class API

    attr_reader :collector, :root, :context

    def initialize(options = {})
      @collector  = Collector.new(options[:nodes] || [])
      @root       = options[:root]     || {}
      @context    = options[:context]  || []
    end

    def context?(kind)
      context.include?(kind)
    end

    def where(params = {})
      return add_context(:where, :filter) unless params.any?
      add_nodes Factory.where_nodes(params, context + [:where, :filter])
    end

    def match(params = {})
      return add_context(:match, :query) unless params.any?
      add_nodes Factory.match_nodes(params, context + [:match, :query])
    end

    def query(params = {})
      return add_context(:query) unless params.any?
      add_nodes Factory.raw_node(params, context + [:query])
    end

    def filter(params = {})
      return add_context(:filter) unless params.any?
      add_nodes Factory.raw_node(params, context + [:filter])
    end

    def or(params = {})
      return add_context(:or) unless params.any?
      add_nodes params
    end

    def should(params = {})
      return add_context(:should) unless params.any?
      @context << :should
      if context?(:where)
        where(params)
      else
        match(params)
      end
    end

    def not(params = {})
      return add_context(:must_not) unless params.any?
      @context << :must_not
      if context?(:where)
        where(params)
      else
        match(params)
      end
    end

    def request
      @request ||= root.merge(body: {query: collector.json})
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
        new_nodes = Array(additional).map do |n|
          coerce_query_filter(n)
        end
        self.class.new nodes: collector.nodes + new_nodes, root: root
      end

      def add_context(*args)
        @context += args
        self
      end

      def coerce_query_filter(n)
        if n.context?(:query, :filter)
          Factory.query_filter_node(n, n.context)
        else
          n
        end
      end

  end
end
