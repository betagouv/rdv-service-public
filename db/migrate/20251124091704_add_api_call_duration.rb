class AddApiCallDuration < ActiveRecord::Migration[8.0]
  def change
    add_column :api_calls, :duration_in_ms, :integer
  end
end
