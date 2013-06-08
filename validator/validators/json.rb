require 'json'
require 'json-schema'

module AXRValidator
  module Validators
    class JSON < Base
      def validate_syntax
        begin
          ::JSON.parse(@data)
        rescue ::JSON::ParserError => e
          error = Error.new(self.class, 'Syntax error')
          error.location(@file, nil)
          error.attach_to(@validator)

          @syntax_error = true
        end
      end

      def validate_schema(schema_file)
        return if @syntax_error

        unless File.exists?(schema_file)
          error = Warning.new(self.class, "Schema file '#{schema_file}' does not exist")
          error.location(@file, nil)
          error.attach_to(@validator)

          return
        end

        begin
          ::JSON::Validator.validate!(schema_file, @data)
        rescue ::JSON::Schema::ValidationError
          error = Error.new(self.class, "Schema error: #{$!}")
          error.location(@file, nil)
          error.attach_to(@validator)
        end
      end
    end
  end
end
