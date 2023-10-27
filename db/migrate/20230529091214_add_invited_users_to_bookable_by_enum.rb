class AddInvitedUsersToBookableByEnum < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :bookable_by, "agents_and_prescripteurs_and_invited_users"
  end
end
