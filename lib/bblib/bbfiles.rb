# frozen_string_literal: true

module BBLib
  def self.scan_files_and_archives(*args)
    sz = SevenZip.new
    BBLib.scan_files(*args).flat_map do |file|
      if archive?(file)
        sz.list(file).flat_map { |afile, _data| "#{file}//#{afile}" }
      else
        file
      end
    end
  end

  ARCHIVE_EXTENSIONS = %w[bz2 bzip2 tbz2 tbz gz gzip tgz tar wim swm xz txz zip zipx jar xpi odt ods
                          docx xlsx epub apm ar a deb lib arj cab chm chw chi chq msi msp doc xls ppt cpio
                          cramfs dmg ext ext2 ext3 ext4 img fat img hfs hfsx hxs hxi hxr hxq hxw lit ihex
                          iso img lzh lha lzma mbr mslz mub nsis ntfs img mbr rar r00 rpm ppmd qcow qcow2
                          qcow2c 001 squashfs udf iso img scap uefif vdi vhd vmdk wim esd xar pkg z taz ].freeze

  def self.archive?(file)
    ARCHIVE_EXTENSIONS.any? { |ext| file.to_s.end_with?(".#{ext}") }
  end
end
