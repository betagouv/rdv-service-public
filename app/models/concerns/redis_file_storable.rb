module RedisFileStorable
  extend ActiveSupport::Concern

  class FileNotFoundError < StandardError; end

  def load_file
    blob = export_file_blobs.find_by(page_index: nil)
    raise FileNotFoundError, "Can't find file blob for Export##{id}" unless blob

    Zlib.inflate(blob.data)
  end

  def store_file(content)
    transaction do
      update!(computed_at: Time.zone.now)
      export_file_blobs.create!(page_index: nil, data: Zlib.deflate(content))
    end
  end
end
