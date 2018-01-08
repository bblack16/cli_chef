class SevenZip < CLIChef::Cookbook
  class Archive
    class File < Item

      def self.attributes
        'A'
      end

      def filename
        path.file_name
      end

    end
  end
end
