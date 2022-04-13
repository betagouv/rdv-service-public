# frozen_string_literal: true

class TweakReceiptsForEmails < ActiveRecord::Migration[6.1]
  def change
    rename_column :receipts, :sms_content, :content
    add_column :receipts, :email_address, :string
  end
end
