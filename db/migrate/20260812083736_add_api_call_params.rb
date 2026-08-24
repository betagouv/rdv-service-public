class AddApiCallParams < ActiveRecord::Migration[8.0]
  def change
    add_column :api_calls, :param_names, :string, array: true, default: []
  end
end
