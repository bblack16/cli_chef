class SevenZip < CLIChef::Cookbook
  class Archive
    class Item
      include BBLib::Effortless

      attr_str :path, required: true
      attr_of Archive, :archive, serialize: false
      attr_int :size, :packed_size, :volume_index, :offset
      attr_time :modified, :created, :accessed
      attr_str :comment, :crc, :archive_method, :characteristics
      attr_str :host_os, :version
      attr_bool :encrypted, pre_proc: proc { |x| x == '-' }

      init_type :loose

      def self.attributes
        ''
      end

      setup_init_foundation(:attributes) do |a, b|
        a.to_s[0] == b.to_s[0]
      end

      def extract(**opts)
        raise RunTimeError, "No archive has been set for this #{self.class} so it cannot be extracted." unless archive
        SevenZip.extract([archive.path, self.path], **opts)
      end

      def delete(**opts)
        raise RunTimeError, "No archive has been set for this #{self.class} so it cannot be deleted." unless archive
        archive.delete(self.path)
      end
    end
  end
end
