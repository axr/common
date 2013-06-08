module AXRValidator
  module Validators
    class Base
      def initialize(validator, file)
        @validator = validator
        @file = file
        @data = file.read
      end
    end
  end
end
