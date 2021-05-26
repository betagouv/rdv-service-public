# frozen_string_literal: true

class AddPhoneNumberToLieux < ActiveRecord::Migration[6.0]
  def change
    add_column :lieux, :phone_number, :string
    add_column :lieux, :phone_number_formatted, :string
  end
end
