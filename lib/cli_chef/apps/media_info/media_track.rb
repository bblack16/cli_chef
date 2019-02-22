class MediaInfo < CLIChef::Cookbook
  class MediaTrack < Track
    attr_str :format_profile
    attr_int :bit_rate
    attr_float :frame_rate
    attr_str :bit_rate_mode
    attr_bool :forced, pre_proc: proc { |x| x.is_a?(String) ? x.downcase != 'no' : x }
  end
end
