# frozen_string_literal: true

class AddHasOwnSmsProviderToTerritory < ActiveRecord::Migration[6.0]
  def change
    add_column :territories, :has_own_sms_provider, :boolean, default: false
  end
end
