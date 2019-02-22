class MediaInfo < CLIChef::Cookbook
  class TextTrack < Track
    attr_str :codec_id_info
    attr_bool :forced
    attr_str :statistics_tags_issue
    attr_int :bit_rate
    attr_int :frame_count
  end
end
