# frozen_string_literal: true

class RemoveNullConstraintOnRdvIdInReceipts < ActiveRecord::Migration[7.0]
  def change
    change_column_null :receipts, :rdv_id, true
  end
end
