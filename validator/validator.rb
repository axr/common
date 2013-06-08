dir = File.expand_path File.dirname(__FILE__)

require "#{dir}/file_scanner.rb"
require "#{dir}/git_file.rb"

require "#{dir}/message.rb"
require "#{dir}/warning.rb"
require "#{dir}/error.rb"

require "#{dir}/validators/base.rb"
require "#{dir}/validators/generic.rb"
require "#{dir}/validators/json.rb"
require "#{dir}/validators/markdown.rb"

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
