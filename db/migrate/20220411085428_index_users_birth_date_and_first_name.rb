# frozen_string_literal: true

class IndexUsersBirthDateAndFirstName < ActiveRecord::Migration[6.1]
  def change
    add_index :users, :birth_date
    add_index :users, :first_name
  end
end
