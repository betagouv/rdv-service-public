# frozen_string_literal: true

class RemoveDeletedAtFromRdvs < ActiveRecord::Migration[7.0]
  def change
    change_column_null :receipts, :rdv_id, true

    reversible do |direction|
      direction.up do
        Rdv.where.not(deleted_at: nil).each do |rdv|
          rdv.skip_webhooks = true
          rdv.destroy
        end
      end
    end

    remove_column :rdvs, :deleted_at, :datetime
  end
end
