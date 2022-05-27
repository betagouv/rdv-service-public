# frozen_string_literal: true

class AddTerritoryToUsers < ActiveRecord::Migration[6.1]
  def up
    create_table :user_territories do |t|
      t.references :user
      t.references :territory
      t.timestamps
    end

    User.includes(:organisations).find_each do |user|
      user.update!(territories: user.organisations.map(&:territory).uniq)
    end
  end

  def down
    drop_table :user_territories
  end
end
