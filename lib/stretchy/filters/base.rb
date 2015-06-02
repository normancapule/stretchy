require 'stretchy/utils/validation'

module Stretchy
  module Filters
    class Base

      include Utils::Validation

      def initialize
        raise "Override this in subclass"
      end

      def to_search
        raise "Override this in subclass"
      end

    end
  end
end
