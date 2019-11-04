class UserHabtmOrganisations < ActiveRecord::Migration[6.0]
  class User < ActiveRecord::Base
    belongs_to :organisation, optional: true
    has_and_belongs_to_many :organisations, -> { distinct }
  end

  def up
    create_table :organisations_users, id: false do |t|
      t.belongs_to :organisation, index: true
      t.belongs_to :user, index: true
    end

    User.all.each do |u|
      u.organisations << u.organisation if u.organisation
    end

    remove_column :users, :organisation_id
  end

  def down
    add_column :users, :organisation_id, :bigint
    add_index :users, :organisation_id

    User.all.each do |u|
      u.organisation = u.organisations.first
      u.save
    end

    drop_table :organisations_users
  end
end
