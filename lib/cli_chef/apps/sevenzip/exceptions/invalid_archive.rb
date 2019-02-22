class SevenZip < CLIChef::Cookbook
  class InvalidArchive < Exception

    def initialize(path)
      @path = path
      super("Invalid or corrupted archive: #{path}")
    end

    def path
      @path
    end

  end
end
