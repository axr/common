module AXRValidator
  class Message
    attr_accessor :type_name

    def initialize(owner, message)
      @owner = owner
      @message = message

      @file = nil
      @line = nil
    end

    def location(file, line)
      @file = file
      @line = line
    end

    def attach_to(validator)
      validator.attach_message self
    end

    def to_string
      string = "[#{@type_name}] #{@owner} \"#{@message}\""

      unless @file.nil?
        string += "\n    in file #{@file.path}"
        string += ":#{@line}" unless @line.nil?
      end

      return string
    end
  end
end
