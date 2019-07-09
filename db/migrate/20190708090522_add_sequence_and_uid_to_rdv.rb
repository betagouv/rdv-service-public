class AddSequenceAndUidToRdv < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'uuid-ossp'
    add_column :rdvs, :sequence, :integer, null: false, default: 0
    add_column :rdvs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
  end
end
