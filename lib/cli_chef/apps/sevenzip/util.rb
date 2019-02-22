module BBLib
  def self.scan_files_and_archives(path, *filters, recursive: false, archive_types: SevenZip::SUPPORTED_ARCHIVES, &block)
    matches         = []
    filters         = filters.map { |filter| filter.is_a?(Regexp) ? filter : /^#{Regexp.quote(filter).gsub('\\*', '.*')}$/ }
    archive_filters = archive_types.map { |type| /\.#{Regexp.quote(type)}$/i }

    scan_files(path, *(filters + archive_filters), recursive: recursive) do |file|
      if archive_filters.any? { |filter| filter =~ file } && !filters.any? { |filter| filter =~ file }
        match = false
        begin
          SevenZip.list_files(file).select do |archive|
            match = true if filters.any? { |filter| filter =~ archive.path }
          end
        rescue => _e
          # Nothing, archive check failed
        end
        if match
          matches << file
          yield file if block_given?
        end
      else
        matches << file
        yield file if block_given?
      end
    end
    matches
  end
end
