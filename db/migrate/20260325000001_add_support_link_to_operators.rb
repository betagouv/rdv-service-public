class AddSupportLinkToOperators < ActiveRecord::Migration[8.0]
  def change
    add_column :operators, :support_link, :string
  end
end
