require "csv"

module CsvOrXlsReader
  class Importer
    def initialize(form_file)
      @form_file = form_file
      @extension = File.extname(@form_file.original_filename)&.tr(".", "")&.downcase&.to_sym

      if @extension == :csv
        extend CsvImporter
      elsif @extension == :xls
        extend XlsImporter
      else
        raise "unsupported format: #{@extension}"
      end
    end
  end

  module CsvImporter
    def rows
      CSV.read(@form_file.tempfile, headers: :first_row).map(&:to_h)
    end
  end

  module XlsImporter
    def rows
      book = Spreadsheet.open(@form_file.tempfile)
      worksheet = book.worksheets.first
      header_row = worksheet.row(0)
      worksheet.each(1).map { header_row.zip(_1.map(&:to_s)).to_h }
    end
  end
end
