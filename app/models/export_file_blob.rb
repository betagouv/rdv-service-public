class ExportFileBlob < ApplicationRecord
  belongs_to :export

  scope :pages, -> { where.not(page_index: nil) }
end
