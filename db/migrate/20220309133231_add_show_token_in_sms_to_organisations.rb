# frozen_string_literal: true

class AddShowTokenInSmsToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :show_token_in_sms, :boolean, default: false
  end
end
