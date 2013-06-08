module AXRValidator
  class FileScanner
    attr_accessor :source

    def initialize
      # Values:
      # :fs - Scan from file system
      # :index - Scan from Git index
      # :cached - Scan from staging area
      @source = :fs
    end

    def on(regex)
      case @source
      when :cached
        list = `git diff --name-only --cached --diff-filter=ACMR`.split("\n")

      when :index
        list = `git ls-files`.split("\n")

      when :fs
        list = Dir.glob("**/*")
      end

      list.each do |path|
        next if /(^|\/)\.git(\/|$)/.match path
        next if ::File.directory?(path)

        next unless regex.match path

        file = GitFile.new(path)
        file.source = @source

        next if file.binary?

        yield file
      end
    end
  end
end
