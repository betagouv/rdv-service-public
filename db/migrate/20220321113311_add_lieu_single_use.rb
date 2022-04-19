# frozen_string_literal: true

class AddLieuSingleUse < ActiveRecord::Migration[6.1]
  def change
    # Replace Lieu#enabled by Lieu#availability
    create_enum :lieu_availability, %i[enabled disabled single_use]
    add_column :lieux, :availability, :lieu_availability
    up_only do
      Lieu.where(enabled: true).update_all(availability: :enabled)
      Lieu.where(enabled: false).update_all(availability: :disabled)
    end
    change_column_null :lieux, :availability, false
    add_index :lieux, :availability
    remove_index :lieux, :enabled
    rename_column :lieux, :enabled, :old_enabled

    # Also make existing Lieu#organisation_id, name and address nonnull (there is already a validation in Rails)
    change_column_null :lieux, :organisation_id, false
    change_column_null :lieux, :name, false
    change_column_null :lieux, :address, false
  end
end
