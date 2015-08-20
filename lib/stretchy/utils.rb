module Stretchy
  module Utils

    def self.is_empty?(arg = nil)
      UTILS.is_empty?(arg)
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

    class UtilsModule
      include Utils
    end

    UTILS = UtilsModule.new

  end
end
