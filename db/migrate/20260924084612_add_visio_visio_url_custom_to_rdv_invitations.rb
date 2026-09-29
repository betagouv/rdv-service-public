class AddVisioVisioUrlCustomToRdvInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :rdv_invitations, :visio_url_custom, :string
  end
end
