require "csv"

module CsvOrXlsReader
  class Importer
    def initialize(form_file)
      @form_file = form_file
      @extension = File.extname(@form_file.original_filename)&.tr(".", "")&.downcase&.to_sym

      case @extension
      when :csv
        extend CsvImporter
      when :xls
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
      worksheet.each(1).map do |row|
        header_row.zip(row.map { cast_value(_1) }).to_h
      end
    end

    def cast_value(cell_value)
      # workaround https://github.com/zdavatz/spreadsheet/issues/41
      # XLS does not store Floats properly
      return cell_value.to_i.to_s if cell_value.is_a?(Float) && cell_value.to_s.ends_with?(".0")

      cell_value.to_s
    end
  end
end
