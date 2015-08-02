module Stretchy
  class Node

    attr_reader :json, :context

    def initialize(json, context = [])
      @json    = json
      @context = context
    end

    def context?(*args)
      args.all? {|c| context.include?(c) }
    end

  end
end
