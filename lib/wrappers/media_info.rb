module BBLib

  class MediaInfo < CLIChef::Cookbook

    def initialize path = nil
      self.init 'MediaInfo', 'MediaInfo is a convenient unified display of the most relevant technical and tag data for video and audio files.', path
    end

    def info file, full:false
      i = run(file:file, full:full)[:response]
      data = {}
      i.split("\n\n").each do |s|
        lines = s.split("\n")
        cat = lines.delete_at(0).to_s.strip.to_clean_sym
        next unless cat.to_s != ''
        data[cat] = Hash.new
        lines.each do |l|
          data[cat][l.split(':').first.to_clean_sym] = l.split(':')[1..-1].join(':').strip
        end
      end
      data
    end

    def help
      run({help:nil})[:response]
    end

    protected

      def setup_exit_codes
        @exit_codes = {
          0 => 'No error',
          1 =>	'Failure'
        }
      end

      def setup_default_locations
        @default_locations = ['C:/Program Files/MediaInfo/MediaInfo.exe', 'C:/Program Files(x86)/MediaInfo/MediaInfo.exe', 'C:/7-Zip/7z.exe']
      end

      def setup_recipes
        # None currently
      end

      def setup_ingredients
        tsv = %"name	description	flag	default	allowed_values	aliases	encapsulator
help	Display the CLI help.	--help	nil	nil
full	Full information Display (all internal tags)	-f	nil	nil
output_html	Full information Display with HTML tags	--Output=HTML	nil	nil	html
output_xml	Full information Display with XML tags	--Output=XML	nil	nil	xml
file	The file to get tags out of		nil	String		\"
"
        @cabinet.from_tsv tsv
      end

  end



end
