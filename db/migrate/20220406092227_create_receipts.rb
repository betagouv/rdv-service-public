# frozen_string_literal: true

class CreateReceipts < ActiveRecord::Migration[6.1]
  def change
    create_enum :receipts_channel, %i[sms mail webhook]
    create_enum :receipts_result, %i[processed sent delivered failure]

    create_table :receipts do |t|
      t.references :rdv
      t.references :user
      t.string :event, null: false
      t.column :channel, :receipts_channel, null: false
      t.column :result, :receipts_result, null: false
      t.string :error_message
      t.timestamps null: false

      # SMS specific columns
      t.string :sms_provider
      t.integer :sms_count
      t.string :sms_content
      t.string :sms_phone_number

      t.index :created_at
      t.index :event
      t.index :channel
      t.index :result
    end
  end
end
