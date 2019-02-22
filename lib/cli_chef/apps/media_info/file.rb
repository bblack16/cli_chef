require_relative 'track'
require_relative 'media_track'
require_relative 'audio_track'
require_relative 'video_track'
require_relative 'text_track'
require_relative 'menu_track'

class MediaInfo < CLIChef::Cookbook
  class File
    include BBLib::Effortless

    init_type :collect
    collect_method :extra_attributes

    attr_str :path, required: true, arg_at: 0
    attr_str :id
    attr_ary_of Track, :tracks
    attr_str :format, :format_version
    attr_int :size
    attr_float :duration
    attr_int :bit_rate
    attr_str :bit_rate_mode
    attr_str :description, :writing_application, :writing_library
    attr_str :album, :album_performer, :performer
    attr_str :title
    attr_time :encoded_date
    attr_hash :extra_attributes

    [:audio, :video, :text, :menu].each do |track_type|
      define_method("#{track_type}_tracks") do
        tracks.find_all { |t| t.type == track_type }
      end

      define_method("#{track_type}?") do
        tracks.any? { |t| t.type == track_type }
      end

      define_method("#{track_type}") do
        matches = send("#{track_type}_tracks")
        return nil if matches.empty?
        matches.find(&:default?) || matches.first
      end
    end

    def type
      video? ? :video : :audio
    end

  end
end
