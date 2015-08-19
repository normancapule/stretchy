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
      boost_params = Hash[BOOST_OPTIONS.map do |opt|
        [opt, params.delete(opt)]
      end].keep_if {|k,v| !!v}
      boost_params = {weight: DEFAULT_WEIGHT} unless boost_params.any?

      filter = if context[:query]
        params_to_boost_query(params, boost_params, context)
      else
        params_to_boost_filter(params, boost_params, context)
      end
    end

    def params_to_boost_query(params, boost_params, context = default_context)
      queries = params.map do |field, val|
        {match: {field => {query: val}}}
      end

      combined = combine_bools_by_context(queries, context)
      Node.new(
        boost_params.merge(filter: {query: combined}),
        context
      )
    end

    def params_to_boost_filter(params, boost_params, context = default_context)
      filters = params.map do |field, val|
        {terms: {field => Array(val)}}
      end
      combined = combine_bools_by_context(filters, context)
      Node.new(
        boost_params.merge(filter: combined),
        context
      )
    end

    def combine_bools_by_context(bools, context)
      if bools.count == 1 &&
         !(context[:must_not] || context[:should])

        bools.first
      else
        if context[:should]
          if context[:must_not]
            {bool: {should: {bool: {must_not: bools}}}}
          else
            {bool: {should: bools}}
          end
        else
          if context[:must_not]
            {bool: {must_not: bools}}
          else
            {bool: {must: bools}}
          end
        end
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

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functionfieldvaluefactor
    def field_value_function_node(params = {}, context = default_context)
      Node.new({field_value_factor: params}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functionrandom
    def random_score_function_node(seed, context = default_context)
      Node.new({random_score: { seed: seed}}, context)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/current/querydslfunctionscorequery.html#functiondecay
    def decay_function_node(params = {}, context = default_context)
      decay_fn = params.delete(:decay_function)
      field    = params.delete(:field)
      Node.new({decay_fn => { field => params}}, context)
    end

  end
end
