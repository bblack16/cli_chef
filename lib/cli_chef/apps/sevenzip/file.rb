class SevenZip < CLIChef::Cookbook
  class Archive
    class File < Item

      def self.folder
        '-'
      end

      def filename
        path.file_name
      end

    end
  end
end
