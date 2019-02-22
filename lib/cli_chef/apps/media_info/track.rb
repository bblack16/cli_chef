class MediaInfo < CLIChef::Cookbook
  class Track
    include BBLib::Effortless
    include BBLib::TypeInit

    init_type :collect
    collect_method :extra_attributes

    attr_int :id
    attr_int :size
    attr_str :title
    attr_float :duration
    attr_str :format, :format_info, :codec_id
    attr_str :compression_mode, :writing_library, :language
    attr_bool :default, default: false, pre_proc: proc { |x| x.is_a?(String) ? x.downcase != 'no' : x }
    attr_hash :extra_attributes

    def self.type
      super.to_s.sub('_track', '').to_sym
    end

  end
end
