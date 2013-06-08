module AXRValidator
  module Validators
    class Markdown < Base
      def validate_line_length
        line_number = 1

        @data.split("\n").each do |line|
          # The line is part of a code block
          next if line.start_with? "\t"

          # The line starts with HTML
          next if line =~ /^<\w+\s.+>/

          # The line ends with an image or a link
          next if line =~ /[!]?\[[^\]]+\]\([^\)]+\)[.,:]?$/

          if line.length > 80
            error = Error.new(self.class, "Line longer than 80 characters")
            error.location(@file, line_number)
            error.attach_to(@validator)
          end

          line_number += 1
        end
      end
    end
  end
end
