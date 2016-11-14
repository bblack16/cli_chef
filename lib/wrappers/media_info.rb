# frozen_string_literal: true
class MediaInfo < CLIChef::Cookbook
  def help
    run(help: nil)
  end

  def version
    run(version: true).scan(/(?<= v)\d+\.\d+.*/).first
  end

  def info(file, **args)
    args.delete(:non_blocking)
    run({ file: file }.merge(args)).split("\n\n").map do |category|
      lines = category.split("\n")
      if lines.empty?
        nil
      else
        name = lines.delete_at(0).strip.downcase.to_clean_sym
        lines.map do |line|
          line_split = line.split(':', 2)
          [
            "#{name == :general ? nil : "#{name}_"}#{line_split.first.strip.downcase}".to_clean_sym,
            convert_value(line_split.last.strip)
          ]
        end
      end
    end.compact.flatten(1).to_h
  end

  protected

  def setup_defaults
    self.name        = :media_info
    self.description = 'MediaInfo is a convenient unified display of the most relevant technical and tag data for video and audio files.'

    add_exit_codes(
      0 => 'No error',
      1 => 'Failure'
    )

    add_default_location(
      'C:/Program Files/MediaInfo/MediaInfo.exe',
      'C:/Program Files(x86)/MediaInfo/MediaInfo.exe'
    )

    add_ingredient(
      { name: :help, description: 'Display the CLI help.', flag: '--help', allowed_values: [nil], aliases: [:h] },
      { name: :version, description: 'Display MediaInfo version and exit', flag: '--Version', allowed_values: [nil], aliases: [:v] },
      { name: :full, description: 'Full information Display (all internal tags)', flag: '-f', allowed_values: [nil], aliases: [:verbose] },
      { name: :output_html, description: 'Full information Display with HTML tags', flag: '--Output=HTML', allowed_values: [nil], aliases: [:html] },
      { name: :output_xml, description: 'Full information Display with XML tags', flag: '--Output=XML', allowed_values: [nil], aliases: [:xml] },
      { name: :file, description: 'The file to get tags out of', flag: '', allowed_values: [String], aliases: [:input] }
    )
  end

  def convert_value(value)
    if (value.to_i.to_s == value rescue false)
      value.to_i
    else
      value
    end
  end
end
