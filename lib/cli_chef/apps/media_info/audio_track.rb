class MediaInfo < CLIChef::Cookbook
  class AudioTrack < MediaTrack
    attr_float :channels
    attr_str :channel_positions, :sampling_rate
    attr_str :statistics_tags_issue
    attr_int :frame_count
    attr_str :mode, :mode_extensions
    attr_str :bit_rate_mode, :replay_gain, :replay_gain_peak
    attr_float :delay
  end
end
