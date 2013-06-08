module AXRValidator
  class Error < Message
    def initialize(validator, message)
      @type_name = "ERROR"

      self.class.superclass.instance_method(:initialize)
        .bind(self).call(validator, message)
    end
  end
end
