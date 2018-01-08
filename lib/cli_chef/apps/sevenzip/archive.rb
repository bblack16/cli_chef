require_relative 'item'
require_relative 'file'
require_relative 'dir'

class SevenZip < CLIChef::Cookbook
  class Archive
    include BBLib::Effortless

    attr_file :path, required: true
    attr_ary_of File, :files
    attr_ary_of Dir, :dirs

    after :path=, :load_archive

    def size
      ::File.size(path)
    end

    def extract(**opts)
      SevenZip.extract(path, **opts)
    end

    def add(file, **opts)
      SevenZip.add(path, file, **opts)
    end

    def delete(file, **opts)
      SevenZip.delete(path, file, **opts)
    end

    protected

    def load_archive
      self.files.clear
      items = SevenZip.list(self.path)
      items.map { |i| i.archive = self }
      self.dirs = items.find_all { |i| i.is_a?(Dir) }
      self.files = items.find_all { |i| !i.is_a?(Dir) }
      true
    end

  end
end
