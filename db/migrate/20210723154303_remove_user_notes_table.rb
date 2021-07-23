# frozen_string_literal: true

class RemoveUserNotesTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :user_notes do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :organisation, null: false, foreign_key: true
      t.belongs_to :agent, null: true, foreign_key: true
      t.text :text
      t.timestamps
    end
  end
end
