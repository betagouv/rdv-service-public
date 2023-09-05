# frozen_string_literal: true

class RemoveDeletedAtFromRdvs < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        Rdv.where.not(deleted_at: nil).destroy_all
      end

      remove_column :rdvs, :deleted_at, :datetime
    end
  end
end
