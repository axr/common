module AXRValidator
  module Validators
    class Generic < Base
      def validate_whitespace
        return if @bom_detected

        line_number = 1

        @data.split("\n").each do |line|
          if line.include? "\r"
            error = Error.new(self.class, "CR detected")
            error.location(@file, line_number)
            error.attach_to(@validator)

            # Skip to next line
            next
          end

          if line =~ /\s$/
            error = Error.new(self.class, "Trailing whitespace detected")
            error.location(@file, line_number)
            error.attach_to(@validator)
          end

          line_number += 1
        end

        if !(@data =~ /[^\n]\n\z/)
          error = Error.new(self.class, "The file must end with exactly one blank line")
          error.location(@file, line_number - 1)
          error.attach_to(@validator)
        end
      end

      def validate_encoding_utf8
        unless @data.encoding == ::Encoding::UTF_8
          error = Error.new(self.class, "Non-UTF-8 encoding detected: '#{@data.encoding.name}'")
          error.location(@file, nil)
          error.attach_to(@validator)
        end

        if @data[0, 3] == "\xEF\xBB\xBF"
          error = Error.new(self.class, "UTF-8 BOM detected")
          error.location(@file, 1)
          error.attach_to(@validator)

          @bom_detected = true
        end
      end

      def validate_indentation(char)
        line_number = 1

        @data.split("\n").each do |line|
          md = /^(\s)/.match(line)
          next if md.nil?

          if md[0] != char
            error = Error.new(self.class, "Invalid indentation used")
            error.location(@file, line_number)
            error.attach_to(@validator)
          end

          line_number += 1
        end
      end
    end
  end
end
