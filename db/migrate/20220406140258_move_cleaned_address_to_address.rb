# frozen_string_literal: true

class MoveCleanedAddressToAddress < ActiveRecord::Migration[6.1]
  def change
    # Move out the existing address (and make it optional)
    rename_column :lieux, :address, :old_address
    change_column_null :lieux, :old_address, true

    # Make sure the clean address is set, and start using it
    change_column_null :lieux, :cleaned_address, false
    rename_column :lieux, :cleaned_address, :address

    up_only { Lieu.touch_all } # Make sure cache is invalidated
  end
end
