require_relative "file_scanner.rb"
require_relative "git_file.rb"

require_relative "message.rb"
require_relative "warning.rb"
require_relative "error.rb"

require_relative "validators/base.rb"
require_relative "validators/generic.rb"
require_relative "validators/json.rb"
require_relative "validators/markdown.rb"

module AXRValidator
  class Validator
    attr_reader :messages

    def initialize
      @messages = []
      @messages_count = {
        Error.name => 0,
        Warning.name => 0
      }
    end

    def attach_message(message)
      @messages.push message
      @messages_count[message.class.name] += 1
    end

    def end
      exit (@messages_count[Error.name] > 0 ? 1 : 0)
    end
  end
end
