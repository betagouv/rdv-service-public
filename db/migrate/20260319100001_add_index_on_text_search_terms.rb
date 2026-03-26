class AddIndexOnTextSearchTerms < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :text_search_terms, using: :gin, algorithm: :concurrently
  end
end
