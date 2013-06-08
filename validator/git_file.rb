module AXRValidator
  class GitFile
    attr_reader :path
    attr_accessor :source

    def initialize(path)
      @path = path
      @source = :fs
    end

    def read
      return File.read(@path) if @source == :fs
      return _read_at 'HEAD' if @source == :index
      return _read_at '' if @source == :cached
    end

    def binary?
      return read.include? "\0"
    end

    def _read_at(sha)
      sha = sha.sub /[^a-zA-Z0-9]/, ''
      return `git show #{sha}:#{@path}` if $?.to_i == 0
    end
  end
end
