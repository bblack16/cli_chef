class SevenZip < CLIChef::Cookbook

  def initialize path: nil
    self.init '7Zip', '7-Zip is a file archiver with a high compression ratio.', path
  end

  def list archive, parse:true, show_technical: true, include_archives: nil, disable_parsing: nil, exclude_archives: nil, include: nil, password:nil, recurse:nil, type:nil, exclude:nil
    cook(:list, {archive:archive, show_technical:show_technical, include_archives: include_archives, disable_parsing: disable_parsing, exclude_archives: exclude_archives, include: include, password:password, recurse:recurse, type:type, exclude:exclude})
    return nil if @result[:exit][:code] > 1
    parse ? parse_list : @result[:response]
  end

  def file_list archive, include:nil, exclude:nil
    list(archive, include:include, exclude:exclude).hash_path('..archives..files..path')
  end

  def add file, output, type:nil, include:nil, exclude:nil, recurse:nil, volumes:nil, working_dir:nil, password:nil, method:nil
    good = true
    [file].flatten.each do |f|
      cook(:add, {file:file, output:output, type:type, include:include, exclude:exclude, recurse:recurse, volumes:volumes, working_dir:working_dir, password:password, method:method, file:[output, file]})
      if !@result[:response].include? 'Everything is Ok' then good = false end
    end
    good
  end

  def update archive, file:nil, include:nil, password:nil, recurse:nil, stdout:nil, exclude:nil, stdin:nil, working_dir:nil, create_sfx:nil, compress_shared_files:nil, type:nil, update_switch:nil
    cook(:update, {archive:archive, file:file, include:include, password:password, recurse:recurse, stdout:stdout, exclude:exclude, stdin:stdin, working_dir:working_dir, create_sfx:create_sfx, compress_shared_files:compress_shared_files, type:type, update_switch:update_switch})[:response].include? 'Everything is Ok'
  end

  def delete archive, file, include:nil, exclude:nil, method:nil, password:nil, update:nil, working_dir:nil
    cook(:delete, archive:archive, file:file, include:include, exclude:exclude, method:method, password:password, update:update, working_dir:working_dir)[:response].include? 'Everything is Ok'
  end

  def extract archive, output:nil, full_paths: true, password:nil, type:nil, include:nil, exclude:nil, recurse:nil, stdout:nil
    cook(:extract, {extract:!full_paths, extract_full_paths:full_paths, archive:archive, output:output, password:password, type:type, include:include, exclude:exclude, recurse:recurse, stdout:stdout})[:response].include? 'Everything is Ok'
  end

  def benchmark
    cook(:benchmark)[:response]
  end

  def test archive, file:nil, include:nil, include_archives:nil, password:nil, recurse:nil, disable_parsing:nil, exclude:nil, exclude_archives:nil
    cook(:test, {archive:archive, file:file, include:include, include_archives:include_archives, password:password, recurse:recurse, disable_parsing:disable_parsing, exclude:exclude, exclude_archives:exclude_archives})[:response].include? 'Everything is Ok'
  end

  def help
    run({help:nil})
  end

  protected

    def parse_list
      res = @result[:response]
      basics = res.split("\n").find{ |l| l =~ /\d+ file/i }.scan(/\d+/).map{ |n| n.to_i }
      info = {file_count: basics[0], size: basics[1], archives: {}}
      res.split('Listing archive: ')[1..-1].each do |archive|
        name = archive.split("\n").first.strip.gsub('\\', '/')
        id = info[:archives].size
        info[:archives][id] = {files: []}
        sec = info[:archives][id]
        # Get Archive Details
        archive.split('----------').first.split('--').last.split("\n").each do |dl|
          if dl.include? '='
            v = dl.split('=').last.strip
            if v.to_i.to_s == v then v = v.to_i end
            sec[dl.split('=').first.to_clean_sym] = v
          end
        end
        # Get File Details
        archive.split('----------')[1].split("\n\n").each do |file|
          f = Hash.new
          file.split("\n").each do |dt|
            if dt.include? '='
              v = dt.split('=').last.strip
              if v.to_i.to_s == v then v = v.to_i end
              f[dt.split('=').first.to_clean_sym] = v
            end
          end
          sec[:files] << f
        end
        sec[:path] = name

      end
      info
    end

    def setup_exit_codes
      @exit_codes = {
        0 => 'No error',
        1 =>	'Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.',
        2	=> 'Fatal error',
        7	=> 'Command line error',
        8	=> 'Not enough memory for operation',
        255	=> 'User stopped the process'
      }
    end

    def setup_default_locations
      @default_locations = ['C:/Program Files/7-Zip/7z.exe', 'C:/Program Files(x86)/7-Zip/7z.exe', 'C:/7-Zip/7z.exe']
    end

    def setup_recipes
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new 'list', ingredients: ({list:true, archive:nil, show_technical: true, include_archives: nil, disable_parsing: nil, exclude_archives: nil, include: nil, password:nil, recurse:nil, type:nil, exclude:nil}), required_input: [:archive]
      @recipe_book[:list].description = 'Gets a list of all files within an archive. The path to the archive or a wildcard path must be provided. By default this recipe shows technical information using the slt ingredient.'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new 'add', ingredients: ({add:true, type:'7z', include:nil, exclude:nil, recurse:nil, volumes:nil, working_dir:nil, password:nil, method:nil}), required_input: [:file, :output]
      @recipe_book[:add].description = 'Adds a file to the specified archive. If the archive does not exist it is created. Both the input file and output archive are required arguments and must be valid file paths. The :type ingredient can be used to toggle what type of archive is created. By default it is a 7z.'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new 'extract', ingredients: ({extract_full_paths:true, extract:false, output:nil, type:nil, include:nil, exclude:nil, recurse:nil, include_archives:nil, exclude_archives:nil, password:nil, overwrite_mode:nil, stdout:false, assume_yes:true}), required_input: [:archive]
      @recipe_book[:extract].description = 'Extracts files from an archive. The archive must be specified and must be a valid path. By default everything will be extracted into the directory of the archive. Use the :output ingredient to toggle a different location to extract files. By default full paths mode is used. For standard extract pass {extract:true, extract_full_paths:false} as ingredients.'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new :benchmark, ingredients:({benchmark:true})
      @recipe_book[:benchmark].description = 'Measures speed of the CPU and checks RAM for errors. No arguments required'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new :delete, ingredients:({delete:true, archive:nil, file:nil, include:nil, method:nil, password:nil, update_switch:nil, working_dir:nil, exclude:nil}), required_input: [:archive, :file]
      @recipe_book[:delete].description = 'Deletes files from an archive. Use :archive to specify the path to the archive, and :file to specify either the file name or wildcarded file name(s) (*) to remove from the archive.'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new :test, ingredients:({test:true, archive:nil, file:nil, include:nil, include_archives:nil, password:nil, recurse:nil, disable_parsing:nil, exclude:nil, exclude_archives:nil}), required_input: [:archive]
      @recipe_book[:test].description = 'Tests an archive. Use :archive to specify the archive file. You may also test only certain files within the archive using the :file ingredient.'
      @recipe_book.add_recipe BBLib::CLIChef::Recipe.new :update, ingredients:({update:true, archive:nil, file:nil, include:nil, password:nil, recurse:nil, stdout:nil, exclude:nil, stdin:nil, working_dir:nil, create_sfx:nil, compress_shared_files:nil, type:nil, update_switch:nil}), required_input: [:archive]
      @recipe_book[:update].description = 'Update older files in the archive and add files that are not already in the archive. Use :archive to specify the archive to update and :file to control what file(s) is updated.'
    end

    def setup_ingredients
      tsv = %"name	description	flag	default	allowed_values	aliases	spacer	encapsulator
add	Adds files to archive.	a	nil	nil	a
extract	Extracts files from an archive to the current directory or to the output directory.	e	nil	nil	e
extract_full_paths	Extracts files from an archive with their full paths in the current directory, or in an output directory if specified.	x	nil	nil	x
benchmark	Measures speed of the CPU and checks RAM for errors.	b	nil	nil	b
delete	Deletes files from archive.	d	nil	nil	d
list	Lists contents of archive.	l	nil	nil	l
test	Tests archive files.	t	nil	nil	t
update	Update older files in the archive and add files that are not already in the archive.	u	nil	nil	u
archive	Specifies the name of the archive		nil	String	file		\"
include	Specifies additional include filenames and wildcards.	-i	nil	String			\"
method	Specifies the compression method.	-m	nil	String
password	Specifies password.	-p	nil	String
recurse	Specifies the method of treating wildcards and filenames on the command line.    -r  Enable recurse subdirectories.    -r-  Disable recurse subdirectories. This option is default for all commands.    -r0  Enable recurse subdirectories only for wildcard names.	-r	nil	nil|'-'|'0'|0
create_sfx	Creates self extracting archive.	-sfx	nil	nil|'7z.sfx'|'tzCon.sfx'|'7zS.sfx'|'7zSD.sfx'
stdin	Causes 7-Zip to read data from stdin (standard input) instead of from disc files.	-si	nil	nil|String
stdout	Causes 7-Zip to write output data to stdout (standard output stream).	-so	nil	nil|String
compress_shared_files	Compresses files open for writing by another applications.	-ssw	nil	nil
type	Specifies the type of archive.	-t	zip	'*'|'7z'|'xz'|'split'|'zip'|'gzip'|'bzip2'|'tar'|'mbr'|'vhd'|'udf'
update_switch	Specifies how to update files in an archive and (or) how to create new archives.	-u	nil
volumes	Specifies volume sizes.	-v	1g	/\d+[bkmg]/i
working_dir	Sets the working directory for the temporary base archive.	-w	nil	String			\"
exclude	Specifies which filenames or wildcarded names must be excluded from the operation.	-x	nil	String
include_archives	Specifies additional include archive filenames and wildcards.	-ai	nil	String			\"
disable_parsing	Disables parsing of the archive_name field on the command line.	-an	nil	nil
overwrite	Specifies the overwrite mode during extraction, to overwrite files already present on disk.	-ao	s	's'|'a'|'u'|'t'	overwrite_mode
exclude_archives	Specifies archives to be excluded from the operation.	-ax	nil	String			\"
output_dir	Specifies a destination directory where files are to be extracted.	-o	nil	String	output_directory|output		\"
assume_yes	Disables most of the normal user queries during 7-Zip execution.	-y	nil	nil	yes|assume|answer_yes
show_technical_information	Sets technical mode for l (List) command.	-slt	nil	nil	slt|technical|show_technical
"
      @cabinet.from_tsv tsv
    end
    
end
