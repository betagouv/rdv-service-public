# frozen_string_literal: true

class AddPhoneNumberIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :phone_number_formatted
  end
end
