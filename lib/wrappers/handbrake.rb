# frozen_string_literal: true
class Handbrake < CLIChef::Cookbook

  attr_reader :status

  def help
    run(help: nil)
  end

  def encode(input, output, **args)
    reset_status
    args = { input: input, output: output, non_blocking: true }.merge(args)
    run(args) do |line, stream|
      process_encode_line(line, stream) rescue nil
    end
  end


  alias reencode encode

  def eta_time
    return nil unless running?
    Time.now + @status[:eta].to_i
  end

  def method_missing(*args)
    if @status.include?(args.first)
      @status[args.first]
    else
      super
    end
  end

  protected

  def setup_defaults
    self.name        = :handbrake
    self.description = 'HandBrake is a tool for converting video from nearly any format to a selection of modern, widely supported codecs.'

    add_exit_codes(
      { code: 0, description: 'Clean exit' },
      { code: 1, description: 'Cancelled', error: true },
      { code: 2, description: 'Invalid Input', error: true },
      { code: 3, description: 'Initialization Error', error: true },
      { code: 4, description: 'Unknown Error', error: true }
    )

    add_default_location(
      'handbrakecli.exe',
      'hanbrakecli',
      'C:/Program Files/Handbrake/HandbrakeCLI.exe',
      'C:/Program Files(x86)/Handbrake/HandbrakeCLI.exe',
      'C:/Handbrake/HandbrakeCLI.exe'
    )

    add_ingredient(
      { name: :help, description: 'Print help', flag: '--help', allowed_values: [nil], aliases: [:h] },
      { name: :update, description: 'Check for updates and exit', flag: '--update', allowed_values: [nil], aliases: [] },
      { name: :verbose, description: 'Be verbose (optional argument: logging level)', flag: '--verbose', allowed_values: [1, 2, 3], aliases: [] },
      { name: :preset, description: 'Use a built-in preset. Capitalization matters, and if the preset name has spaces, surround it with double quotation marks', flag: '--preset', allowed_values: [String], aliases: [] },
      { name: :preset_list, description: 'See a list of available built-in presets', flag: '--preset-list', allowed_values: [nil], aliases: [] },
      { name: :no_dvd_nav, description: 'Do not use dvdnav for reading DVDs', flag: '--no-dvdnav', allowed_values: [nil], aliases: [] },
      { name: :no_open_cl, description: 'Disable use of OpenCL', flag: '--no-opencl', allowed_values: [nil], aliases: [] },
      { name: :input, description: 'Set input device', flag: '--input', allowed_values: [String], aliases: [] },
      { name: :title, description: 'Select a title to encode (0 to scan all titles only', flag: '--title', allowed_values: [Fixnum, String], aliases: [] },
      { name: :min_duration, description: 'Set the minimum title duration (in seconds). Shorter  titles will not be scanned.', flag: '--min-duration', allowed_values: [Fixnum], aliases: [] },
      { name: :scan, description: 'Scan selected title only.', flag: '--scan', allowed_values: [nil], aliases: [] },
      { name: :main_feature, description: 'Detect and select the main feature title.', flag: '--main-feature', allowed_values: [nil], aliases: [] },
      { name: :chapters, description: 'Select chapters (e.g. \'1-3\' for chapters 1 to 3, or \'3\' for chapter 3 only', flag: '--chapters', allowed_values: [], aliases: [] },
      { name: :angle, description: 'Select the video angle (DVD or Blu-ray only)', flag: '--angle', allowed_values: [Fixnum], aliases: [] },
      { name: :previews, description: 'Select how many preview images are generated, and whether or not they\'re stored to disk (0 or 1).', flag: '--previews', allowed_values: [String], aliases: [] },
      { name: :start_at_preview, description: 'Start encoding at a given preview.', flag: '--start-at-preview', allowed_values: [(1..30)], aliases: [] },
      { name: :start_at, description: 'Start encoding at a given frame, duration (in seconds), or pts (on a 90kHz clock)', flag: '--start-at', allowed_values: [Object], aliases: [] },
      { name: :stop_at, description: 'Stop encoding at a given frame, duration (in seconds), or pts (on a 90kHz clock)', flag: '--stop-at', allowed_values: [Object], aliases: [] },
      { name: :output, description: 'Set output file name', flag: '--output', allowed_values: [String], aliases: [:out] },
      { name: :format, description: 'Set output container format (av_mp4/av_mkv)', flag: '--format', allowed_values: ['mp4', 'mkv', :mp4, :mkv], aliases: [] },
      { name: :markers, description: 'Add chapter markers', flag: '--markers', allowed_values: [String], aliases: [] },
      { name: :large_file, description: 'Create 64-bit mp4 files that can hold more than 4 GB of data. Note: breaks pre-iOS iPod compatibility.', flag: '--large-file', allowed_values: [nil], aliases: [] },
      { name: :optimize, description: 'Optimize mp4 files for HTTP streaming (\'fast start\')', flag: '--optimize', allowed_values: [nil], aliases: [] },
      { name: :ipod_atom, description: 'Mark mp4 files so 5.5G iPods will accept them', flag: '--ipod-atom', allowed_values: [nil], aliases: [] },
      { name: :use_open_cl, description: 'Use OpenCL where applicable', flag: '--use-opencl', allowed_values: [nil], aliases: [] },
      { name: :use_hwd, description: 'Use DXVA2 hardware decoding', flag: '--use-hwd', allowed_values: [nil], aliases: [] },
      { name: :encoder, description: 'Set video library encoder. Options: x264/x265/mpeg4/mpeg2/VP8/theora', flag: '--encoder', allowed_values: ['x264', 'x265', 'mpeg4', 'mpeg2', 'VP8', 'theora', :x264, :x265, :mpeg4, :mpeg2, :VP8, :vp8, :theora], aliases: [] },
      { name: :encoder_preset, description: 'Adjust video encoding settings for a particular speed/efficiency tradeoff (encoder-specific)', flag: '--encoder-preset', allowed_values: [Object], aliases: [] },
      { name: :encoder_preset_list, description: 'List supported --encoder-preset values for the specified video encoder', flag: '--encoder-preset-list', allowed_values: [nil], aliases: [] },
      { name: :encoder_tune, description: 'Adjust video encoding settings for a particular  type of souce or situation (encoder-specific)', flag: '--encoder-tune', allowed_values: [Object], aliases: [] },
      { name: :encoder_tune_list, description: 'List supported --encoder-tune values for the  specified video encoder', flag: '--encoder-tune-list', allowed_values: [nil], aliases: [] },
      { name: :encopts, description: 'Specify advanced encoding options in the same  style as mencoder (all encoders except theora):  option1=value1:option2=value2', flag: '--encopts', allowed_values: [Object], aliases: [] },
      { name: :encoder_profile, description: 'Ensures compliance with the requested codec   profile (encoder-specific)', flag: '--encoder-profile', allowed_values: [Object], aliases: [] },
      { name: :encoder_profile_list, description: 'List supported --encoder-profile values for the   specified video encoder', flag: '--encoder-profile-list', allowed_values: [nil], aliases: [] },
      { name: :encoder_level, description: 'Ensures compliance with the requested codec  level (encoder-specific)', flag: '--encoder-level', allowed_values: [Object], aliases: [] },
      { name: :encoder_level_list, description: 'List supported --encoder-level values for the  specified video encoder', flag: '--encoder-level-list', allowed_values: [nil], aliases: [] },
      { name: :quality, description: 'Set video quality', flag: '--quality', allowed_values: [Fixnum], aliases: [] },
      { name: :video_bitrate, description: 'Set video bitrate', flag: '--vb', allowed_values: [Fixnum], aliases: [:vb, :bitrate] },
      { name: :two_pass, description: 'Use two-pass mode', flag: '--two-pass', allowed_values: [nil], aliases: [] },
      { name: :turbo, description: 'When using 2-pass use \'turbo\' options on the  1st pass to improve speed (only works with x264)', flag: '--turbo', allowed_values: [nil], aliases: [] },
      { name: :video_framerate, description: 'Set video framerate (5/10/12/15/23.976/24/25/29.97/30/50/59.94/60).  Be aware that not specifying a framerate lets  HandBrake preserve a source\'s time stamps,  potentially creating variable framerate video', flag: '--rate', allowed_values: [Float, Fixnum], aliases: [:framerate] },
      { name: :variable_framerate, description: 'VFR preserves the source timing.', flag: '--vfr', allowed_values: [nil], aliases: [] },
      { name: :constant_framerate, description: 'CFR makes the output constant rate at the rate given by the -r flag (or the source\'s average rate if no -r is given)', flag: '--cfr', allowed_values: [nil], aliases: [] },
      { name: :peak_limited_framerate, description: 'PFR doesn\'t allow the rate to go over the rate specified  with the -r flag but won\'t change the source  timing if it\'s below that rate.', flag: '--pfr', allowed_values: [nil], aliases: [] },
      { name: :audio_tracks, description: 'Select audio track(s), separated by commas', flag: '--audio', allowed_values: [String], aliases: [] },
      { name: :audio_encoder, description: 'Audio encoder(s): av_aac, fdk_aac, fdk_haac, copy:aac, ac3, copy:ac3, copy:dts, copy:dtshd, mp3, copy:mp3, vorbis, flac16, flac24, copy. copy:* will passthrough the corresponding audio unmodified to the muxer if it is a supported passthrough audio type. Separated by commas for more than one audio track.', flag: '--aencoder', allowed_values: ['av_aac', 'fdk_aac', 'fdk_haac', 'copy:aac', 'ac3', 'copy:ac3', 'copy:dts', 'copy:dtshd', 'mp3', 'copy:mp3', 'vorbis', 'flac16', 'flac24', 'copy', :av_aac, :fdk_aac, :fdk_haac, :attr_array_removeraac, :ac3, :copy_ac3, :copy_dts, :copy_dtshd, :mp3, :copy_mp3, :vorbis, :flac16, :flac24, :copy], aliases: [] },
      { name: :audio_copy_mask, description: 'Set audio codecs that are permitted when the \'copy\' audio encoder option is specified (aac/ac3/dts/dtshd/mp3, default: all).', flag: '--audio-copy-mast', allowed_values: ['all', 'aac', 'ac3', 'dts', 'dtshd', 'mp3', :all, :aac, :ac3, :drs, :dtshd, :mp3], aliases: [] },
      { name: :audio_fallback, description: 'Set audio codec to use when it is not possible to copy an audio track without re-encoding.', flag: '--audio-fallback', allowed_values: ['av_aac', 'fdk_aac', 'fdk_haac', 'copy:aac', 'ac3', 'copy:ac3', 'copy:dts', 'copy:dtshd', 'mp3', 'copy:mp3', 'vorbis', 'flac16', 'flac24', 'copy', :av_aac, :fdk_aac, :fdk_haac, :attr_array_removeraac, :ac3, :attr_array_removerac3, :attr_array_removerdts, :attr_array_removerdtshd, :mp3, :attr_array_removermp3, :vorbis, :flac16, :flac24, :copy], aliases: [] },
      { name: :audio_bitrate, description: 'Set audio bitrate(s) (default: depends on the selected codec, mixdown and samplerate). Separated by commas for more than one audio track.', flag: '--ab', allowed_values: [String, Fixnum], aliases: [:ab] },
      { name: :audio_quality, description: 'Set audio quality metric (default: depends on the selected codec). Separated by commas for more than one audio track.', flag: '--aq', allowed_values: [String, Fixnum], aliases: [] },
      { name: :audio_compression, description: 'Set audio compression metric (default: depends on the selected codec). Separated by commas for more than one audio track.', flag: '--ac', allowed_values: [String, Fixnum], aliases: [] },
      { name: :mixdown, description: 'Format(s) for audio downmixing/upmixing:, mono, left_only, right_only, stereo, dpl1, dpl2, 5point1, 6point1, 7point1, 5_2_lfe .Separated by commas for more than one audio track.', flag: '--mixdown', allowed_values: ['mono', 'left_only', 'right_only', 'stereo', 'dp11', 'dp12', '5point1', '6point1', '7point1', '5_2_lfe', String, Symbol], aliases: [] },
      { name: :normalize_mix, description: 'Normalize audio mix levels to prevent clipping.  Separated by commas for more than one audio track.  0 = Disable Normalization (default)  1 = Enable Normalization', flag: '--normalize-mix', allowed_values: [0, 1], aliases: [] },
      { name: :audio_samplerate, description: 'Set audio samplerate(s) (8/11.025/12/16/22.05/24/32/44.1/48 kHz). Separated by commas for more than one audio track.', flag: '--arate', allowed_values: [String, Float], aliases: [] },
      { name: :dynamic_range_compression, description: 'Apply extra dynamic range compression to the audio, making soft sounds louder. Range is 1.0 to 4.0  (too loud), with 1.5 - 2.5 being a useful range. Separated by commas for more than one audio track.', flag: '--drc', allowed_values: [Float, Fixnum, String], aliases: [] },
      { name: :gain, description: 'Amplify or attenuate audio before encoding.  Does  NOT work with audio passthru (copy). Values are in  dB.  Negative values attenuate, positive values  amplify. A 1 dB difference is barely audible.', flag: '--gain', allowed_values: [Float, Fixnum, String], aliases: [] },
      { name: :audio_dither, description: 'Apply dithering to the audio before encoding. Separated by commas for more than one audio track.  Only supported by some encoders (fdk_aac/fdk_haac/flac16).  Options: auto (default),  none,  rectangular,   triangular,   triangular_hp,  triangular_ns', flag: '--adither', allowed_values: ['auto', 'none', 'rectangular', 'triangular', 'triangular_hp', 'triangular_ns', String, Symbol], aliases: [] },
      { name: :audio_track_name, description: 'Audio track name(s).  Separated by commas for more than one audio track.', flag: '--aname', allowed_values: [String], aliases: [] },
      { name: :width, description: 'Set picture width', flag: '--width', allowed_values: [Fixnum], aliases: [:w] },
      { name: :height, description: 'Set picture height', flag: '--height', allowed_values: [Fixnum], aliases: [:h] },
      { name: :crop, description: 'Set cropping values (default: autocrop)', flag: '--crop', allowed_values: [String, Symbol], aliases: [] },
      { name: :loose_crop, description: 'Always crop to a multiple of the modulus. Specifies the maximum number of extra pixels which may be cropped (default: 15)', flag: '--loose-crop', allowed_values: [String], aliases: [] },
      { name: :max_height, description: 'Set maximum height', flag: '--maxHeight', allowed_values: [Fixnum], aliases: [] },
      { name: :max_width, description: 'Set maximum width', flag: '--maxWidth', allowed_values: [Fixnum], aliases: [] },
      { name: :strict_anamorphic, description: 'Store pixel aspect ratio in video stream', flag: '--strict-anamorphic', allowed_values: [nil], aliases: [] },
      { name: :loose_anamorphic, description: 'Store pixel aspect ratio with specified width', flag: '--loose-anamorphic', allowed_values: [nil], aliases: [] },
      { name: :custom_anamorphic, description: 'Store pixel aspect ratio in video stream and directly control all parameters.', flag: '--custom-anamorphic', allowed_values: [nil], aliases: [] },
      { name: :display_width, description: 'Set the width to scale the actual pixels to at playback, for custom anamorphic.', flag: '--display-width', allowed_values: [Fixnum], aliases: [] },
      { name: :keep_display_aspect, description: 'Preserve the source\'s display aspect ratio when using custom anamorphic', flag: '--keep-display-aspect', allowed_values: [nil], aliases: [] },
      { name: :pixel_aspect, description: 'Set a custom pixel aspect for custom anamorphic (--display-width and --pixel-aspect are mutually exclusive and the former will override the latter)', flag: '--pixel-aspect', allowed_values: [String], aliases: [] },
      { name: :itu_par, description: 'Use wider, ITU pixel aspect values for loose and custom anamorphic, useful with underscanned sources', flag: '--itu-par', allowed_values: [nil], aliases: [] },
      { name: :modulus, description: 'Set the number you want the scaled pixel dimensions to divide cleanly by. Does not affect strict anamorphic mode, which is always mod 2 (default: 16)', flag: '--modulus', allowed_values: [Fixnum], aliases: [] },
      { name: :color_matrix, description: 'Set the color space signaled by the output. Values: 709, pal, ntsc, 601 (same as ntsc) (default: detected from source)', flag: '--color-matrix', allowed_values: [709, 'pal', 'ntsc', 601, :pal, :ntsc], aliases: [] },
      { name: :deinterlace, description: 'Unconditionally deinterlaces all frames  <fast/slow/slower/bob> or omitted (default settings)  or  <YM:FD>  (default 0:-1)', flag: '--deinterlace', allowed_values: ['omitted', 'fast', 'slow', 'slower', 'bob', :omitted, :fast, :slow, :slower, :bob], aliases: [] },
      { name: :decomb, description: 'Selectively deinterlaces when it detects combing <fast/bob> or omitted (default settings) or  <MO:ME:MT:ST:BT:BX:BY:MG:VA:LA:DI:ER:NO:MD:PP:FD>  (default: 7:2:6:9:80:16:16:10:20:20:4:2:50:24:1:-1)', flag: '--decomb', allowed_values: [String], aliases: [] },
      { name: :detelecine, description: 'Detelecine (ivtc) video with pullup filter. Note: this filter drops duplicate frames to restore the pre-telecine framerate, unless you specify a constant framerate (--rate 29.97) <L:R:T:B:SB:MP:FD> (default 1:1:4:4:0:0:-1)', flag: '--detelecine', allowed_values: [String], aliases: [] },
      { name: :denoise, description: 'Denoise video with hqdn3d filter <ultralight/light/medium/strong> or omitted (default settings) or <SL:SCb:SCr:TL:TCb:TCr> (default: 4:3:3:6:4.5:4.5)', flag: '--denoise', allowed_values: [String], aliases: [] },
      { name: :nlmeans, description: 'Denoise video with nlmeans filter <ultralight/light/medium/strong> or omitted or <SY:OTY:PSY:RY:FY:PY:Sb:OTb:PSb:Rb:Fb:Pb:Sr:OTr:PSr:Rr:Fr:Pr> (default 8:1:7:3:2:0)', flag: '--nlmeans', allowed_values: [String], aliases: [] },
      { name: :nimeans_tune, description: 'Tune nlmeans filter to content type. Note: only works in conjunction with presets ultralight/light/medium/strong. <none/film/grain/highmotion/animation> or omitted (default none)', flag: '--nlmeans-tune', allowed_values: ['none', 'film', 'grain', 'highmotion', 'animation', 'omitted', :none, :film, :grain, :highmotion, :animation, :omitted], aliases: [] },
      { name: :deblock, description: 'Deblock video with pp7 filter (default 5:2)', flag: '--deblock', allowed_values: [String], aliases: [] },
      { name: :rotate, description: 'Rotate image or flip its axes. Modes: (can be combined) 1 vertical flip, 2 horizontal flip, 4 rotate clockwise 90 degrees, Default: 3 (vertical and horizontal flip)', flag: '--rotate', allowed_values: [1, 2, 3, 4], aliases: [] },
      { name: :grayscale, description: 'Grayscale encoding', flag: '--grayscale', allowed_values: [nil], aliases: [] },
      { name: :subtitle_track, description: 'Select subtitle track(s), separated by commas. More than one output track can be used for one input.  Example: \'1,2,3\' for multiple tracks. A special track name \'scan\' adds an extra 1st pass.  This extra pass scans subtitles matching the language of the first audio or the language  selected by --native-language. The one that\'s only used 10 percent of the time or less is selected. This should locate subtitles for short foreign language segments. Best used in conjunction with --subtitle-forced.', flag: '--subtitle', allowed_values: [String, Fixnum], aliases: [] },
      { name: :subtitle_forced, description: 'Only display subtitles from the selected stream if the subtitle has the forced flag set. The values in \'string\' are indexes into the subtitle list specified with \'--subtitle\'. Separated by commas for more than one subtitle track. Example: \'1,2,3\' for multiple tracks. If \'string\' is omitted, the first track is forced.', flag: '--subtitle-forced', allowed_values: [String, Fixnum], aliases: [] },
      { name: :subtitle_burned, description: 'Burn\' the selected subtitle into the video track. If \'number\' is omitted, the first track is burned. \'number\' is an index into the subtitle list specified with \'--subtitle\'.', flag: '--subtitle-burned', allowed_values: [String, Fixnum], aliases: [] },
      { name: :subtitle_default, description: 'Flag the selected subtitle as the default subtitle  to be displayed upon playback.  Setting no default means no subtitle will be automatically displayed. If \'number\' is omitted, the first track is default. \'number\' is an index into the subtitle list specified with \'--subtitle\'.', flag: '--subtitle-default', allowed_values: [String, Fixnum], aliases: [] },
      { name: :native_language, description: 'Specifiy your language preference. When the first audio track does not match your native language then select the first subtitle that does. When used in conjunction with --native-dub the audio track is changed in preference to subtitles. Provide the language\'s iso639-2 code (fre, eng, spa, dut, et cetera)', flag: '--native-language', allowed_values: [String], aliases: [] },
      { name: :native_dub, description: 'Used in conjunction with --native-language requests that if no audio tracks are selected the default selected audio track will be the first one that matches the --native-language. If there are no matching audio tracks then the first matching subtitle track is used instead.', flag: '--native-dub', allowed_values: [String], aliases: [] },
      { name: :srt_file, description: 'SubRip SRT filename(s), separated by commas.', flag: '--srt-file', allowed_values: [String], aliases: [] },
      { name: :srt_codeset, description: 'Character codeset(s) that the SRT file(s) are encoded in, separated by commas. Use \'iconv -l\' for a list of valid codesets. If not specified, \'latin1\' is assumed', flag: '--srt-codeset', allowed_values: [String], aliases: [] },
      { name: :srt_offset, description: 'Offset (in milliseconds) to apply to the SRT file(s), separated by commas. If not specified, zero is assumed. Offsets may be negative.', flag: '--srt-offset', allowed_values: [String], aliases: [] },
      { name: :srt_lang, description: 'Language as an iso639-2 code fra, eng, spa et cetera) for the SRT file(s), separated by commas. If not specified, then \'und\' is used.', flag: '--srt-lang', allowed_values: [String], aliases: [] },
      { name: :srt_default, description: 'Flag the selected srt as the default subtitle to be displayed upon playback.  Setting no default means no subtitle will be automatically displayed. If \'number\' is omitted, the first srt is default. \'number\' is an 1 based index into the srt-file list', flag: '--srt-default', allowed_values: [String], aliases: [] },
      { name: :srt_burn, description: 'Burn\' the selected srt subtitle into the video track. If \'number\' is omitted, the first srt is burned. \'number\' is an 1 based index into the srt-file list', flag: '--srt-burn', allowed_values: [String], aliases: [] }
    )
  end

  def process_encode_line(line, _stream)
    @status[:task_count]  = line.scan(/(?<=of )\d+/).first.to_i
    @status[:task]        = line.scan(/\d+(?= of)/).first.to_i
    @status[:fps]         = line.scan(/\d+\.\d+(?= fps)/).first.to_f
    @status[:average_fps] = line.scan(/(?<=avg )\d+\.\d+(?= fps)/).first.to_f
    @status[:eta]         = line.scan(/(?<=ETA ).*?(?=\))/).first.parse_duration rescue nil
    percent               = line.scan(/\d+\.\d+(?= %)/).first.to_f
    if line.include?('Encode done!')
      percent = 100.0
    elsif @status[:task_count] == 2 && percent > 0
      percent /= 2
      percent += 50 if @status[:task] == 2
    end
    @status[:percent] = percent unless percent < @status[:percent].to_i
  rescue StandardError => e
    # Nothing???
  end

  def reset_status
    @status = { percent: 0, task: 1, task_total: nil, eta: nil }
  end
end
