# frozen_string_literal: true

class AddOutlookIdToAgentsRdv < ActiveRecord::Migration[6.1]
  def change
    add_column :agents_rdvs, :outlook_id, :text
  end
end
