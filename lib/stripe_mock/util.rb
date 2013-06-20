module StripeMock
  module Util

    def self.rmerge(hash_one, hash_two)
      return hash_two if hash_one.nil?
      return nil if hash_two.nil?

      hash_one.merge(hash_two) do |key, oldval, newval|
        if oldval.is_a?(Array) && newval.is_a?(Array)
          oldval.zip(newval).map {|elems|
            elems[1].nil? ? elems[0] : rmerge(elems[0], elems[1])
          }
        elsif oldval.is_a?(Hash) && newval.is_a?(Hash)
          rmerge(oldval, newval)
        else
          newval
        end
      end
    end

  end
end
