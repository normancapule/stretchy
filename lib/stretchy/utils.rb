module Stretchy
  module Utils
    module Methods

      # detects empty string, empty array, empty hash, nil
      def is_empty?(arg = nil)
        return true if arg.nil?
        if arg.respond_to?(:any?)
          !arg.any? {|a| !is_empty?(a) }
        elsif arg.respond_to?(:empty?)
          arg.empty?
        else
          !arg
        end
      end

      # raises error if required parameters are missing
      def require_params!(method, params, *fields)
        raise Errors::InvalidParamsError.new(
          "#{method} requires at least #{fields.join(' and ')} params",
          "params found: #{params}"
        ) if fields.any? {|f| is_empty? params[f] }

        true
      end

      # generates a hash of specified options,
      # removing them from the original hash
      def extract_options!(params, list)
        boost_params = Hash[list.map do |opt|
          [opt, params.delete(opt)]
        end].keep_if {|k,v| !is_empty?(v)}
      end

      # must be shared between api & results
      def current_page(offset, limit)
        ((offset + 1.0) / limit).ceil
      end

      # coerces ids to integers, unless they contain non-integers
      def coerce_id(id)
        id =~ /\d+/ ? id.to_i : id
      end
    end

    extend Methods
  end
end
