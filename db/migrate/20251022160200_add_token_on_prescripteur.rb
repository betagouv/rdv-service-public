class AddTokenOnPrescripteur < ActiveRecord::Migration[7.2]
  def change
    add_column :prescripteurs, :token, :string
  end
end
