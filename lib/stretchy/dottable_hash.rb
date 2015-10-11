module Stretchy
  class DottableHash < Hash

    def self.to_dotted(h)
      h.reduce self.new do |memo, arr|
        k, v = arr
        if v.is_a? Hash
          to_dotted(v).each do |subkey, subval|
            memo["#{k}.#{subkey}"] = subval
          end
        else
          memo[k.to_s] = v
        end
        memo
      end
    end

    def self.to_undotted(h)
      h.reduce self.new do |memo, arr|
        k, v = arr
        if k.is_a?(String) || k.is_a?(Symbol)
          subkeys = k.to_s.split('.')
          if subkeys.length > 1
            count = 0
            subkeys.reduce memo do |submemo, subkey|
              count += 1
              if count == subkeys.size
                submemo[subkey.to_sym] = v
              else
                submemo[subkey.to_sym] ||= self.new
                submemo[subkey.to_sym]
              end
            end
          else
            memo[k.to_sym] = v
          end
        else
          memo[k] = v
        end
        memo
      end
    end

    def self.stretchy_symbolize_keys(h)
      h.reduce self.new do |memo, arr|
        k, v = arr
        if v.is_a? Hash
          memo[k.to_sym] = stretchy_symbolize_keys(v)
        else
          memo[k.to_sym] = v
        end
        memo
      end
    end

    def self.stretchy_stringify_keys(h)
      h.reduce self.new do |memo, arr|
        k, v = arr
        if v.is_a? Hash
          memo[k.to_s] = stretchy_stringify_keys(v)
        else
          memo[k.to_s] = v
        end
        memo
      end
    end

    def to_dotted
      self.class.to_dotted self
    end

    def to_undotted
      self.class.to_undotted self
    end
  end
end
