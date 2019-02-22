class MediaInfo < CLIChef::Cookbook
  class VideoTrack < MediaTrack
    attr_str :statistics_tags_issue
    attr_int :width, :height
    attr_str :aspect_ratio
    attr_float :frame_rate
    attr_str :color_space, :chroma_subsampling, :bit_depth
    attr_str :scan_type, :encoding_settings
  end
end
