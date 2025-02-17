class AddApiCallAuthType < ActiveRecord::Migration[7.1]
  def change
    add_column :api_calls, :authentication_type, :string
  end
end
