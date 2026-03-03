class CreateExportFileBlobs < ActiveRecord::Migration[8.0]
  def change
    create_table :export_file_blobs do |t|
      t.uuid :export_id, null: false
      t.integer :page_index
      t.binary :data, null: false
      t.datetime :created_at, null: false
      t.index %i[export_id page_index]
      t.foreign_key :exports
    end
  end
end
