module AXRValidator
  class Warning < Message
    def initialize(validator, message)
      @type_name = "WARNING"

      self.class.superclass.instance_method(:initialize).bind(self).call(validator, message)
    end
  end
end
