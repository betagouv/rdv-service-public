class RemoveShowTokenInSmsFromOrganisations < ActiveRecord::Migration[6.1]
  def change
    remove_column :organisations, :show_token_in_sms, :boolean, default: false
  end
end
