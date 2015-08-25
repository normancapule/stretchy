module Stretchy
  module Factory

    DEFAULT_WEIGHT = 1.5
    BOOST_OPTIONS = [
      :filter,
      :function,
      :weight
    ]
    FUNCTION_SCORE_OPTIONS = [
      :boost,
      :max_boost,
      :score_mode,
      :boost_mode,
      :min_score
    ]

    module_function

    def default_context
      {}
    end

    def extract_boost_params!(params)
      boost_params = Utils.extract_options!(params, BOOST_OPTIONS)
      boost_params = {weight: DEFAULT_WEIGHT} unless boost_params.any?
      boost_params
    end

    def extract_function_score_options!(params)
      Utils.extract_options!(params, FUNCTION_SCORE_OPTIONS)
    end

    def raw_node(params, context)
      Node.new(params, context)
    end

    def raw_boost_node(params, context)
      context[:fn_score]  = extract_function_score_options!(params)
      Node.new(params, context)
    end

    def context_nodes(params, context = default_context)
      if context[:boost]
        params_to_boost(params, context)
      elsif context[:query]
        params_to_queries(params, context)
      else
        params_to_filters(params, context)
      end
    end

    def params_to_boost(params, context = default_context)
      boost_params        = extract_boost_params!(params)
      context[:fn_score]  = extract_function_score_options!(params)
      subcontext          = context.merge(boost: nil)
      nodes               = context_nodes(params, subcontext)
      collector           = AndCollector.new(nodes, subcontext)

      if context[:query]
        Node.new(boost_params.merge(filter: {query: collector.json}), context)
      else
        Node.new(
          boost_params.merge(filter: collector.filter_node.json),
          context
        )
      end
    end

    def params_to_queries(params, context = default_context)
      params.map do |field, val|
        Node.new({match: {field => val}}, context)
      end
    end

    def params_to_filters(params, context = default_context)
      params.map do |field, val|
        case val
        when Range
          Node.new(
            {range: {field: field, gte: val.min, lte: val.max}},
            context
          )
        when nil
          Node.new(
            {missing: {field: field}},
            context
          )
        else
          Node.new(
            {terms: {field => Array(val)}},
            context
          )
        end
      end
    end

    def more_like_node(params = {}, context = default_context)
      Node.new({more_like_this: params}, context)
    end

    # query and filter use the same syntax
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-filter.html
    def range_node(params = {}, context = default_context)
      Node.new({range: params}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-geo-distance-filter.html
    def geo_distance_node(params = {}, context = default_context)
      Node.new({geo_distance: params}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functionfieldvaluefactor
    def field_value_function_node(params = {}, context = default_context)
      context[:fn_score] = extract_function_score_options!(params)
      Node.new({field_value_factor: params}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functionrandom
    def random_score_function_node(seed, context = default_context)
      Node.new({random_score: { seed: seed}}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functiondecay
    def decay_function_node(params = {}, context = default_context)
      boost_params        = extract_boost_params!(params)
      context[:fn_score]  = extract_function_score_options!(params)
      decay_fn            = params.delete(:decay_function)
      field               = params.delete(:field)
      Node.new({decay_fn => { field => params}}.merge(boost_params), context)
    end

  end
end
