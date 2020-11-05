class AddAgentIdToSectorAttributions < ActiveRecord::Migration[6.0]
  def change
    add_reference :sector_attributions, :agent, null: true, foreign_key: true, index: true
  end
end
