# frozen_string_literal: true

class RemoveUnusedRailsTables < ActiveRecord::Migration[7.0]
  def up
    # To recreate, run `bin/rails action_text:install`
    drop_table :action_text_rich_texts

    # To recreate, run `bin/rails active_storage:install`
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs
  end
end
