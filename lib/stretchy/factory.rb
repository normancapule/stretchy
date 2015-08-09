module Stretchy
  module Factory

    DEFAULT_WEIGHT = 1.5
    BOOST_OPTIONS = [
      :filter,
      :function,
      :weight
    ]

    module_function

    def default_context
      {}
    end

    def extract_boost_options(params)
      stripped = params.reject {|k,v| BOOST_OPTIONS.include?(k) }
      options  = params.select {|k,v| BOOST_OPTIONS.include?(k) }
      [stripped, options]
    end

    def raw_node(params, context)
      Node.new(params, context)
    end

    def where_nodes(params, context = default_context)
      params.map do |field, val|
        case val
        when Range
          range_node({field: field, gte: val.min, lte: val.max}, context)
        when nil
          missing_node(field, context)
        else
          terms_node({field: field, values: Array(val)}, context)
        end
      end
    end

    def match_nodes(params, context = default_context)
      params.map do |field, val|
        match_node({field: field, value: val}, context)
      end
    end

    def terms_node(params, context = default_context)
      Node.new(
        { terms: { params[:field] => params[:values] } },
        context
      )
    end

    def match_node(params, context = default_context)
      Node.new(
        { match: { params[:field] => params[:value] }},
        context
      )
    end

    def match_all_node(context = default_context)
      Node.new({match_all: {}}, context)
    end

    def range_node(params, context = default_context)
      json = {}
      json[:gte] = params[:gte] if params[:gte]
      json[:lte] = params[:lte] if params[:lte]
      Node.new({range: {params[:field] => json}}, context)
    end

    def missing_node(field, context = default_context)
      Node.new({missing: { field: field }}, context)
    end

    def not_filter_node(node, context = default_context)
      Node.new({not: node.json }, context)
    end

    # ensures a node is a filter - ie, if it is a query node,
    # wrap it into a query filter
    def filter_node(node)
      if node.context?(:query)
        query_filter_node(node)
      else
        node
      end
    end

    # turns a query node into a filter
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-filter.html
    def query_filter_node(node)
      Node.new(
        { query: node.json },
        node.context
      )
    end

    # combines a query and filter into filtered query
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html
    def filtered_query_node(options = {})
      json = {}
      json[:query]  = options[:query].json  if options[:query]
      json[:filter] = options[:filter].json if options[:filter]
      Node.new({ filtered: json}, options[:context] || [])
    end

    # combines queries into bool query node
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
    #
    # or combines filters into bool filter
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-filter.html
    #
    # fortunately, they use the same syntax
    def bool_node(nodes)
      nodes = Array(nodes)
      return nodes.first unless nodes.count > 1 ||
        nodes.any?{|n| n.context?(:must_not)}   ||
        nodes.any?{|n| n.context?(:should)  }

      must_not = nodes.select{|n| n.context?(:must_not) }
      should   = nodes.select{|n| n.context?(:should) }
      must     = nodes - must_not - should
      json     = {}
      json[:must]     = must.map(&:json)      if must.any?
      json[:must_not] = must_not.map(&:json)  if must_not.any?
      json[:should]   = should.map(&:json)    if should.any?
      Node.new({bool: json}, default_context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#function-field-value-factor
    def field_value_function_node(params = {}, context = default_context)
      Node.new({field_value_factor: params}, context)
    end

    # ensures node is a filter, then merges in boost params
    def filter_function_node(node)
      node   = filter_node(node)
      node   = not_filter_node(node)    if node.context?(:must_not)

      params = node.context[:boost]
      params = {weight: DEFAULT_WEIGHT} unless params.is_a?(Hash)

      Node.new(params.merge(filter: node.json), node.context)
    end

    # ensures node is a valid function, then merges in boost params
    def function_node(node)
      return node if node.context[:boost] == :raw
      filter_function_node(node)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#function-random
    def random_score_function_node(seed, context = default_context)
      Node.new({random_score: { seed: seed}}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#function-decay
    def decay_function_node(params = {}, context = default_context)
      decay_fn = params.delete(:decay_function)
      field    = params.delete(:field)
      Node.new({decay_fn => { field => params}}, context)
    end

    def function_score_query_node(options = {})
      json = {}
      json[:functions] = options[:functions].map(&:json)
      json[:filter]    = options[:filter].json if options[:filter]
      json[:query]     = options[:query].json  if options[:query]
      Node.new({function_score: json}, options[:context] || [])
    end

  end
end
