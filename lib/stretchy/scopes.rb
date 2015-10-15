module Stretchy
  module Scopes

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def stretchify(options = {})
        @stretchy_options = options
      end

      def search(options = {})
        stretchy_scope.new stretchy_options.merge(options)
      end

      def stretchy_options
        Hash(@stretchy_options)
      end

      def stretchy_scope
        @scopes_class ||= Class.new Stretchy::API
      end

      def stretch(name, block)
        stretchy_scope.send(:define_method, name, &block)
      end
    end
  end
end
