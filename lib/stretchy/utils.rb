module Stretchy
  module Utils

    class << self
      def is_empty?(arg = nil)
        UTILS.is_empty?(arg)
      end

      def extract_options!(params, list)
        UTILS.extract_options!(params, list)
      end
    end

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

    # generates a hash of specified options,
    # removing them from the original hash
    def extract_options!(params, list)
      boost_params = Hash[list.map do |opt|
        [opt, params.delete(opt)]
      end].keep_if {|k,v| !is_empty?(v)}
    end

    class UtilsModule
      include Utils
    end

    UTILS = UtilsModule.new

  end
end
