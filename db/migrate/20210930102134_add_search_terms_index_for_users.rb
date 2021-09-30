# frozen_string_literal: true

class AddSearchTermsIndexForUsers < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :search_terms, using: :gin, algorithm: :concurrently
  end
end
