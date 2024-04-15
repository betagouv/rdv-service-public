class ValidateCreateApiCalls < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :api_calls, :agents
  end
end
