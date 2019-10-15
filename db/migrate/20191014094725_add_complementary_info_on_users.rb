class AddComplementaryInfoOnUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :caisse_affiliation, :integer
    add_column :users, :affiliation_number, :string
    add_column :users, :family_situation, :integer
    add_column :users, :number_of_children, :integer
    add_column :users, :logement, :integer
  end
end
