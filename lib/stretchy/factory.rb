module Stretchy
  module Factory

    module_function

    def raw_node(params, context)
      Node.new(params, context)
    end

    def where_nodes(params, context = [])
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

    def match_nodes(params, context = [])
      params.map do |field, val|
        match_node({field: field, value: val}, context)
      end
    end

    def terms_node(params, context = [])
      Node.new(
        { terms: { params[:field] => params[:values] } },
        context
      )
    end

    def match_node(params, context = [])
      Node.new(
        { match: { params[:field] => params[:value] }},
        context
      )
    end

    def match_all_node(context = [])
      Node.new({match: {all: {}}}, context)
    end

    def range_node(params, context = [])
      json = {}
      json[:gte] = params[:gte] if params[:gte]
      json[:lte] = params[:lte] if params[:lte]
      Node.new({range: {params[:field] => json}}, context)
    end

    def missing_node(field, context = [])
      Node.new({missing: { field: field }}, context)
    end

    def not_filter_node(node, context = [])
      Node.new({not: node.json }, context)
    end

    def query_filter_node(node, context = [])
      Node.new(
        { query: node.json },
        context
      )
    end

    def filtered_query_node(options = {})
      json = {}
      json[:query]  = options[:query].json  if options[:query]
      json[:filter] = options[:filter].json if options[:filter]
      Node.new({ filtered: json}, options[:context] || [])
    end

    def bool_node(nodes, context = [])
      must_not = nodes.select{|n| n.context.include?(:must_not) }
      should   = nodes.select{|n| n.context.include?(:should) }
      must     = nodes - must_not - should
      json     = {}
      json[:must]     = must.map(&:json)      if must.any?
      json[:must_not] = must_not.map(&:json)  if must_not.any?
      json[:should]   = should.map(&:json)    if should.any?
      Node.new({bool: json}, context)
    end

    def field_value_function_node(params = {}, context = [])
      Node.new({field_value_factor: params}, context)
    end

    def filter_function_nodes(nodes, params = {}, context = [])
      nodes.map {|n| filter_function_node(n, params, context)}
    end

    def filter_function_node(node, params = {}, context = [])
      Node.new(params.merge(filter: node.json), context)
    end

    def random_score_function_node(seed, context = [])
      Node.new({random_score: { seed: seed}}, context)
    end

    def decay_function_node(params = {}, context = [])
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
