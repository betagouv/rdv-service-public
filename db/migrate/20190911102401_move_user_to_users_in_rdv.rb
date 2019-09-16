class MoveUserToUsersInRdv < ActiveRecord::Migration[5.2]
  def up
    Rdv.all.each do |rdv|
      rdv.users << rdv.user
      rdv.save
    end
  end

  def down
    Rdv.all.each do |rdv|
      rdv.user = rdv.users.first
      rdv.save
    end
  end
end
