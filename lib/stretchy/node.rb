module Stretchy
  class Node

    attr_reader :json, :context
    alias :as_json :json

    def initialize(json, context = {})
      @json    = json
      @context = context
    end

    def empty?
      !@json.any?
    end

    def context?(*args)
      args.all? {|c| !!context[c] }
    end

  end
end
