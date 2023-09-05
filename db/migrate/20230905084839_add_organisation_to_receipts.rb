# frozen_string_literal: true

class AddOrganisationToReceipts < ActiveRecord::Migration[7.0]
  def change
    add_reference :receipts, :organisation, foreign_key: true

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          UPDATE receipts
          SET organisation_id = rdvs.organisation_id
          FROM rdvs
          WHERE rdvs.id = receipts.rdv_id;
        SQL
      end
    end

    change_column_null :receipts, :organisation_id, false
  end
end
