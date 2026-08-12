class AddRdvInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :rdv_invitations do |t|
      t.string :token, null: false
      t.references :user, null: false
      t.references :motif, null: false
      t.references :lieu

      t.references :inviting_agent, null: false
      t.references :rdv

      t.timestamps
    end

    add_foreign_key :rdv_invitations, :users, validate: false
    add_foreign_key :rdv_invitations, :motifs, validate: false
    add_foreign_key :rdv_invitations, :lieux, validate: false
    add_foreign_key :rdv_invitations, :agents, column: :inviting_agent_id, validate: false
  end
end
