module XlsExporter
  def perform
    Spreadsheet.client_encoding = 'UTF-8'
    workbook.write(@file)
    @file.string
  end

  def workbook
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat(header)
    build_lines(sheet)
    book
  end
end
