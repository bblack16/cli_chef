# frozen_string_literal: true
class SevenZip < CLIChef::Cookbook
  def help
    run(help: nil)
  end

  def list(archive, **args)
    run({ list: nil, archive: archive, show_technical: nil }.merge(args))
    result.body.split('Listing archive: ').flat_map { |arch| next if arch.empty?; arch.scan(/(?<=Path = ).*/i)[1..-1] }.compact
  end

  def detailed_list(archive, **args)
    run({ list: nil, archive: archive, show_technical: nil }.merge(args))
    result.body.split('----------').last.split("\n\n").map do |file|
      file.split("\n").map do |line|
        unless line.empty?
          line = line.split(' = ', 2)
          [line.first.downcase.to_clean_sym, convert_value(line.last)]
        end
      end.compact.to_h
    end.map { |f| [f.delete(:path), f] }.to_h
  end

  def add(archive, *files, **args, &block)
    args.delete(:non_blocking)
    files.all? do |file|
      run({ add: nil, archive: [archive, file], yes: nil }.merge(args), &block).body.include?('Everything is Ok') rescue false
    end
  end

  def update(archive, *files, **args)
    args.delete(:non_blocking)
    files.all? do |file|
      run({ update: nil, archive: [archive, file], yes: nil }.merge(args)).body.include?('Everything is Ok')
    end
  end

  def delete(archive, *files, **args)
    args.delete(:non_blocking)
    files.all? do |file|
      run({ delete: nil, archive: [archive, file], yes: nil }.merge(args)).body.include?('Everything is Ok')
    end
  end

  def extract(archive, **args)
    args.delete(:non_blocking)
    type = args[:full_path] == false ? :extract : :extract_full_paths
    run({ type => nil, file: archive, yes: nil }.merge(args)).body.include?('Everything is Ok')
  end

  def test(archive, **args)
    args.delete(:non_blocking)
    run({ test: nil, file: archive, yes: nil }.merge(args)).body.include?('Everything is Ok')
  end

  protected

  def setup_defaults
    self.name        = :sevenzip
    self.description = '7-Zip is a file archiver with a high compression ratio.'

    add_exit_codes(
      { code: 0, description: 'No error' },
      { code: 1, description: 'Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.' },
      { code: 2, description: 'Fatal error', error: true },
      { code: 7, description: 'Command line error', error: true },
      { code: 8, description: 'Not enough memory for operation', error: true },
      { code: 255, description: 'User stopped the process', error: true }
    )

    add_default_location(
      'C:/Program Files/7-Zip/7z.exe',
      'C:/Program Files(x86)/7-Zip/7z.exe',
      'C:/7-Zip/7z.exe'
    )

    add_ingredient(
      { name: :add, description: 'Adds files to archive.', flag: 'a', allowed_values: [nil], aliases: [:a], space: false },
      { name: :extract, description: 'Extracts files from an archive to the current directory or to the output directory.', flag: 'e', allowed_values: [nil], aliases: [:e], space: false },
      { name: :extract_full_paths, description: 'Extracts files from an archive with their full paths in the current directory, or in an output directory if specified.', flag: 'x', allowed_values: [nil], aliases: [:x], space: false },
      { name: :benchmark, description: 'Measures speed of the CPU and checks RAM for errors.', flag: 'b', allowed_values: [nil], aliases: [:b], space: false },
      { name: :delete, description: 'Deletes files from archive.', flag: 'd', allowed_values: [nil], aliases: [:d], space: false },
      { name: :list, description: 'Lists contents of archive.', flag: 'l', allowed_values: [nil], aliases: [:l], space: false },
      { name: :test, description: 'Tests archive files.', flag: 't', allowed_values: [nil], aliases: [:t], space: false },
      { name: :update, description: 'Update older files in the archive and add files that are not already in the archive.', flag: 'u', allowed_values: [nil], aliases: [:u], space: false },
      { name: :archive, description: 'Specifies the name of the archive', flag: nil, allowed_values: [String, Array], aliases: [:file], space: false },
      { name: :include, description: 'Specifies additional include filenames and wildcards.', flag: '-i', allowed_values: [String], aliases: [], space: false },
      { name: :method, description: 'Specifies the compression method.', flag: '-m', allowed_values: [String], aliases: [], space: false },
      { name: :password, description: 'Specifies password.', flag: '-p', allowed_values: [String], aliases: [], space: false },
      { name: :recurse, description: 'Specifies the method of treating wildcards and filenames on the command line.    -r  Enable recurse subdirectories.    -r-  Disable recurse subdirectories. This option is default for all commands.    -r0  Enable recurse subdirectories only for wildcard names.', flag: '-r', allowed_values: [nil, '-', '0', 0], aliases: [], space: false },
      { name: :create_sfx, description: 'Creates self extracting archive.', flag: '-sfx', allowed_values: [nil, '7z.sfx', 'tzCon.sfx', '7zS.sfx', '7zSD.sfx'], aliases: [], space: false },
      { name: :stdin, description: 'Causes 7-Zip to read data from stdin (standard input) instead of from disc files.', flag: '-si', allowed_values: [nil, String], aliases: [], space: false },
      { name: :stdout, description: 'Causes 7-Zip to write output data to stdout (standard output stream).', flag: '-so', allowed_values: [nil, String], aliases: [], space: false },
      { name: :compress_shared_files, description: 'Compresses files open for writing by another applications.', flag: '-ssw', allowed_values: [nil], aliases: [], space: false },
      { name: :type, description: 'Specifies the type of archive.', flag: '-t', allowed_values: ['*', '7z', 'xz', 'split', 'zip', 'gzip', 'bzip2', 'tar', 'mbr', 'vhd', 'udf'], aliases: [], space: false },
      { name: :update_switch, description: 'Specifies how to update files in an archive and (or) how to create new archives.', flag: '-u', allowed_values: [], aliases: [], space: false },
      { name: :volumes, description: 'Specifies volume sizes.', flag: '-v', allowed_values: [/\d+[bkmg]/i], aliases: [], space: false },
      { name: :working_dir, description: 'Sets the working directory for the temporary base archive.', flag: '-w', allowed_values: [String], aliases: [], space: false },
      { name: :exclude, description: 'Specifies which filenames or wildcarded names must be excluded from the operation.', flag: '-x', allowed_values: [String], aliases: [], space: false },
      { name: :include_archives, description: 'Specifies additional include archive filenames and wildcards.', flag: '-ai', allowed_values: [String], aliases: [], space: false },
      { name: :disable_parsing, description: 'Disables parsing of the archive_name field on the command line.', flag: '-an', allowed_values: [nil], aliases: [], space: false },
      { name: :overwrite, description: 'Specifies the overwrite mode during extraction, to overwrite files already present on disk.', flag: '-ao', allowed_values: %w(s a u t), aliases: [:overwrite_mode], space: false },
      { name: :exclude_archives, description: 'Specifies archives to be excluded from the operation.', flag: '-ax', allowed_values: [String], aliases: [], space: false },
      { name: :output_dir, description: 'Specifies a destination directory where files are to be extracted.', flag: '-o', allowed_values: [String], aliases: [:output_directory, :output], space: false },
      { name: :assume_yes, description: 'Disables most of the normal user queries during 7-Zip execution.', flag: '-y', allowed_values: [nil], aliases: [:yes, :assume, :answer_yes], space: false },
      { name: :show_technical_information, description: 'Sets technical mode for l (List) command.', flag: '-slt', allowed_values: [nil], aliases: [:slt, :technical, :show_technical], space: false },
      { name: :help, description: 'Display the CLI help.', flag: '-h', allowed_values: [nil], aliases: [:h], space: false }
    )
  end

  def convert_value(value)
    if (value.to_i.to_s == value rescue false)
      value.to_i
    elsif (Time.parse(value) rescue false)
      Time.parse(value)
    else
      value
    end
  end
end
