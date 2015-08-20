module Stretchy
  module Utils

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

  end
end
