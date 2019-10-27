require 'cli_chef' unless defined?(CLIChef::VERSION)
require_relative 'sevenzip/exceptions/exception'
require_relative 'sevenzip/archive'
require_relative 'sevenzip/util'

class SevenZip < CLIChef::Cookbook

  SUPPORTED_ARCHIVES = [
    '001', '7z', 'a', 'apm', 'ar', 'arj', 'bz2', 'bzip2', 'cab', 'chi', 'chm',
    'chq', 'chw', 'cpio', 'cramfs', 'deb', 'dmg', 'doc', 'docx', 'epub', 'esd',
    'ext', 'ext2', 'ext3', 'ext4', 'fat', 'gz', 'gzip', 'hfs', 'hfsx', 'hxi',
    'hxq', 'hxr', 'hxs', 'hxw', 'ihex', 'img', 'iso', 'jar', 'lha', 'lib',
    'lit', 'lzh', 'lzma', 'mbr', 'msi', 'mslz', 'msp', 'mub', 'nsis', 'ntfs',
    'ods', 'odt', 'pkg', 'ppmd', 'ppt', 'qcow', 'qcow2', 'qcow2c', 'r00', 'rar',
    'rpm', 'scap', 'squashfs', 'swm', 'tar', 'taz', 'tbz', 'tbz2', 'tgz', 'txz',
    'udf', 'uefif', 'vdi', 'vhd', 'vmdk', 'wim', 'xar', 'xls', 'xlsx', 'xpi',
    'xz', 'z', 'zip', 'zipx'
  ].freeze

  self.description = '7-Zip is a file archiver with a high compression ratio.'

  add_exit_codes(
    { code: 0, description: 'No error' },
    { code: 1, description: 'Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.' },
    { code: 2, description: 'Fatal error', error: true },
    { code: 7, description: 'Command line error', error: true },
    { code: 8, description: 'Not enough memory for operation', error: true },
    { code: 255, description: 'User stopped the process', error: true }
  )

  add_default_locations(
    'C:/Program Files/7-Zip/7z.exe',
    'C:/Program Files(x86)/7-Zip/7z.exe',
    'C:/7-Zip/7z.exe',
    '7za',
    '7z'
  )

  add_ingredients(
    { name: :add, description: 'Adds files to archive.', flag: 'a', allowed_values: [nil], aliases: [:a], boolean_argument: true, flag_delimiter: '' },
    { name: :extract, description: 'Extracts files from an archive to the current directory or to the output directory.', flag: 'e', allowed_values: [nil], aliases: [:e], boolean_argument: true, flag_delimiter: '' },
    { name: :extract_full_paths, description: 'Extracts files from an archive with their full paths in the current directory, or in an output directory if specified.', flag: 'x', allowed_values: [nil], aliases: [:x], boolean_argument: true, flag_delimiter: '' },
    { name: :benchmark, description: 'Measures speed of the CPU and checks RAM for errors.', flag: 'b', allowed_values: [nil], aliases: [:b], boolean_argument: true, flag_delimiter: '' },
    { name: :delete, description: 'Deletes files from archive.', flag: 'd', allowed_values: [nil], aliases: [:d], boolean_argument: true, flag_delimiter: '' },
    { name: :list, description: 'Lists contents of archive.', flag: 'l', allowed_values: [nil], aliases: [:l], boolean_argument: true, flag_delimiter: '' },
    { name: :test, description: 'Tests archive files.', flag: 't', allowed_values: [nil], aliases: [:t], boolean_argument: true, flag_delimiter: '' },
    { name: :update, description: 'Update older files in the archive and add files that are not already in the archive.', flag: 'u', allowed_values: [nil], aliases: [:u], boolean_argument: true, flag_delimiter: '' },
    { name: :archive, description: 'Specifies the name of the archive', flag: nil, allowed_values: [String, Array], aliases: [:file], flag_delimiter: '' },
    { name: :include, description: 'Specifies additional include filenames and wildcards.', flag: '-i', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :method, description: 'Specifies the compression method.', flag: '-m', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :password, description: 'Specifies password.', flag: '-p', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :recurse, description: 'Specifies the method of treating wildcards and filenames on the command line.    -r  Enable recurse subdirectories.    -r-  Disable recurse subdirectories. This option is default for all commands.    -r0  Enable recurse subdirectories only for wildcard names.', flag: '-r', allowed_values: [nil, '-', '0', 0], aliases: [], flag_delimiter: '' },
    { name: :create_sfx, description: 'Creates self extracting archive.', flag: '-sfx', allowed_values: [nil, '7z.sfx', 'tzCon.sfx', '7zS.sfx', '7zSD.sfx'], aliases: [], flag_delimiter: '' },
    { name: :stdin, description: 'Causes 7-Zip to read data from stdin (standard input) instead of from disc files.', flag: '-si', allowed_values: [nil], aliases: [], boolean_argument: true, flag_delimiter: '' },
    { name: :stdout, description: 'Causes 7-Zip to write output data to stdout (standard output stream).', flag: '-so', allowed_values: [nil], aliases: [], boolean_argument: true, flag_delimiter: '' },
    { name: :compress_shared_files, description: 'Compresses files open for writing by another applications.', flag: '-ssw', allowed_values: [nil], aliases: [], flag_delimiter: '' },
    { name: :type, description: 'Specifies the type of archive.', flag: '-t', allowed_values: ['*', '7z', 'xz', 'split', 'zip', 'gzip', 'bzip2', 'tar', 'mbr', 'vhd', 'udf'], aliases: [], flag_delimiter: '' },
    { name: :update_switch, description: 'Specifies how to update files in an archive and (or) how to create new archives.', flag: '-u', allowed_values: [], aliases: [], flag_delimiter: '' },
    { name: :volumes, description: 'Specifies volume sizes.', flag: '-v', allowed_values: [/\d+[bkmg]/i], aliases: [], flag_delimiter: '' },
    { name: :working_dir, description: 'Sets the working directory for the temporary base archive.', flag: '-w', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :exclude, description: 'Specifies which filenames or wildcarded names must be excluded from the operation.', flag: '-x', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :include_archives, description: 'Specifies additional include archive filenames and wildcards.', flag: '-ai', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :disable_parsing, description: 'Disables parsing of the archive_name field on the command line.', flag: '-an', allowed_values: [nil], aliases: [], flag_delimiter: '' },
    { name: :overwrite, description: 'Specifies the overwrite mode during extraction, to overwrite files already present on disk.', flag: '-ao', allowed_values: %w(s a u t), aliases: [:overwrite_mode], flag_delimiter: '' },
    { name: :exclude_archives, description: 'Specifies archives to be excluded from the operation.', flag: '-ax', allowed_values: [String], aliases: [], flag_delimiter: '' },
    { name: :output_dir, description: 'Specifies a destination directory where files are to be extracted.', flag: '-o', allowed_values: [String], aliases: [:output_directory, :output], flag_delimiter: '' },
    { name: :assume_yes, description: 'Disables most of the normal user queries during 7-Zip execution.', flag: '-y', allowed_values: [nil], aliases: [:yes, :assume, :answer_yes], boolean_argument: true, flag_delimiter: '' },
    { name: :show_technical_information, description: 'Sets technical mode for l (List) command.', flag: '-slt', allowed_values: [nil], aliases: [:slt, :technical, :show_technical], boolean_argument: true, flag_delimiter: '' },
    { name: :help, description: 'Display the CLI help.', flag: '-h', allowed_values: [nil], aliases: [:h], boolean_argument: true, flag_delimiter: '' },
    { name: :show_progress, description: 'Print progress to stdout.', flag: '-bsp1', allowed_values: [nil], aliases: [], boolean_argument: true, flag_delimiter: '' },
    { name: :files, description: 'Add file name or pattern arguments to various options', flag: nil, allowed_values: [String, Array], aliases: [:file], boolean_argument: false, flag_delimiter: '' }
  )

  def help
    run!(help: true).body
  end

  def version
    help.scan(/(?<=7-zip )\d+\.\d+\s?\w*/i).first
  end

  def self.archive?(file)
    ext = File.extname(file).sub('.', '').downcase
    SUPPORTED_ARCHIVES.include?(ext) || ext =~ /^\d{3}$/
  end

  def self.archive(path)
    SevenZip::Archive.new(path: path)
  end

  bridge_method :archive

  def list(archive, **opts)
    args = { list: true, archive: archive, show_technical: true }.merge(opts.except(:list, :archive, :show_technical))
    result = run!(args)
    raise(InvalidArchive, archive) if result.body =~ /Can not open the file as archive/i
    archive = Archive.new(archive)
    result.body.split('----------', 2).last.split("\n\n").map do |details|
      hash = details.split("\n").hmap do |attribute|
        next if attribute.empty?
        key, value = attribute.split(' = ', 2)
        [key.downcase.gsub(/\s+/, '_').to_sym, value]
      end
      next unless hash[:path]
      hash[:folder] = (hash[:size] || 0).to_i.zero? ? '+' : '-' unless hash.include?(:folder)
      Archive::Item.new(hash.merge(archive: archive))
    end.compact
  end

  def list_files(archive, **opts)
    list(archive, **opts).select { |i| i.is_a?(SevenZip::Archive::File) }
  end

  def list_dirs(archive, **opts)
    list(archive, **opts).select { |i| i.is_a?(SevenZip::Archive::Dir) }
  end

  def extract(archive, **opts)
    type = opts[:full_path] == false ? :extract : :extract_full_paths
    args = { type => true, file: archive, yes: true, show_progress: opts[:stdout] ? false : true }.merge(opts.except(type, :file, :yes))
    run(**args) do |line, stream, job|
      job.percent = line.extract_numbers.first if line =~ /\d+\%/
      job.process_line(line, stream)
    end
  end

  def extract!(archive, **opts)
    extract(archive, opts.merge(synchronous: true))
  end

  [:add, :update, :delete].each do |type|
    define_method(type) do |archive, file, **opts|
      args = { type => true, archive: [archive, file], yes: true }.merge(opts.except(type, :archive, :yes))
      run(**args)
    end

    define_method("#{type}!") do |archive, file, **opts|
      send(type, archive, file, opts.merge(synchronous: true))
    end
  end

  # TODO Have test return something better
  def test(archive, **opts)
    args = { test: true, file: archive, yes: nil }.merge(opts.except(:test, :file, :yes))
    run(**args)
  end

  def test!(archive, **opts)
    test(archive, opts.merge(synchronous: true))
  end

  def self.multi_part?(file)
    path = File.dirname(file)
    case file
    when /\.r\d+$/, /\.part\d+/i, /\.\d+$/
      true
    else
      !BBLib.scan_files(path, /#{file.file_name(false).sub(/part\d+$/, '')}\.(r\d+$|\d+$|\.part\d+[\.$])/i).empty?
    end
  end

  def self.all_parts(file)
    path = File.dirname(file)
    (BBLib.scan_files(path, /#{file.file_name(false).sub(/\.part\d+$/, '')}\.(r\d+$|\d+$|part\d+[\.$])/i) << file).uniq.sort
  end

  def self.first_part(file)
    path = File.dirname(file)
    case file
    when /\.r\d+$/
      base = file.file_name.sub(/\.r\d+$/i, '')
      Dir.entries(path).map do |file|
        next unless /#{Regexp.escape(base)}\.r\d+$/i =~ file
        return File.join(path, file) if file =~ /\.rar$/i
        part_number = file.scan(/(?<=r)\d+$/i).first.to_i
        [part_number, File.join(path, file)]
      end.sort_by { |a| a[0] }&.first&.last
    when /\.part\d+/i
      base = file.file_name.sub(/\.part\d+[\.$].*/i, '')
      Dir.entries(path).map do |file|
        next unless /#{Regexp.escape(base)}\.part\d+[\.$]/i =~ file
        return File.join(path, file) if file =~ /\.rar$|\.7z$/i
        part_number = file.scan(/(?<=\.part)\d+/i).first.to_i
        [part_number, File.join(path, file)]
      end.sort_by { |a| a[0] }&.first&.last
    when /\.\d+$/
      base = file.file_name.sub(/\.\d+$/, '')
      Dir.entries(path).map do |file|
        next unless /#{Regexp.escape(base)}\.\d+$/ =~ file
        part_number = file.scan(/(?<=\.)\d+$/).first.to_i
        [part_number, File.join(path, file)]
      end.sort_by { |a| a[0] }&.first&.last
    else
      return file
    end || file
  end
end
