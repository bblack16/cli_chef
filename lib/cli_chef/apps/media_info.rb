require 'cli_chef' unless defined?(CLIChef::VERSION)

class MediaInfo < CLIChef::Cookbook
  self.description = 'MediaInfo is a convenient unified display of the most relevant technical and tag data for video and audio files.'

  add_exit_codes(
    { code: 0, description: 'No error' },
    { code: 1, description: 'Failure' }
  )

  add_default_locations(
    'C:/Program Files/MediaInfo/MediaInfo.exe',
    'C:/Program Files(x86)/MediaInfo/MediaInfo.exe'
  )

  add_ingredients(
    { name: :help, description: 'Display the CLI help.', flag: '--help', allowed_values: [nil], aliases: [:h], boolean_argument: true },
    { name: :version, description: 'Display MediaInfo version and exit', flag: '--Version', allowed_values: [nil], aliases: [:v], boolean_argument: true },
    { name: :full, description: 'Full information Display (all internal tags)', flag: '-f', allowed_values: [nil], aliases: [:verbose], boolean_argument: true },
    { name: :output_html, description: 'Full information Display with HTML tags', flag: '--Output=HTML', allowed_values: [nil], aliases: [:html], boolean_argument: true },
    { name: :output_xml, description: 'Full information Display with XML tags', flag: '--Output=XML', allowed_values: [nil], aliases: [:xml], boolean_argument: true },
    { name: :file, description: 'The file to get tags out of', flag: '', allowed_values: [String], aliases: [:input] }
  )

  def help
    run!(help: true).body
  end

  def version
    run!(version: true).body.scan(/(?<= v)\d+\.\d+.*/).first
  end

  def info(file, full = false)
    run!(file: file, full: full).body.split("\n\n").hmap do |category|
      lines = category.split("\n")
      next if lines.empty?
      [
        lines.shift.strip.downcase.method_case,
        lines.hmap do |line|
          key, value = line.split(':', 2)
          key = key.downcase.method_case.to_sym
          [
            key,
            convert_value(key, value.strip)
          ]
        end
      ]
    end.keys_to_sym
  end

  protected

  def convert_value(key, value)
    case key
    when :file_size
      value.parse_file_size
    when :duration
      value.parse_duration
    when :width, :height
      value.to_i
    else
      value
    end
  end
end
