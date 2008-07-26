module Dabcup
  module MassAssignment
    def attributes
      attrs = {}
      instance_variables.each do |name|
        attrs[name] = __send__(name)
      end
      attrs
    end

    def attributes=(attributes)
      attributes.each do |name, value|
        __send__(name.to_s + '=', value)
      end
    end
  end
end