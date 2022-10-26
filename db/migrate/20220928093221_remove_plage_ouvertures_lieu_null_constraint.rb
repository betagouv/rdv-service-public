# frozen_string_literal: true

class RemovePlageOuverturesLieuNullConstraint < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:plage_ouvertures, :lieu_id, true)
  end
end
