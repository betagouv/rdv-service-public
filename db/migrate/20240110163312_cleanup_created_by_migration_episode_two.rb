class CleanupCreatedByMigrationEpisodeTwo < ActiveRecord::Migration[7.0]
  # See https://github.com/ankane/strong_migrations#setting-not-null-on-an-existing-column
  def change
    validate_check_constraint :rdvs, name: "rdvs_created_by_type_null"
    validate_check_constraint :participations, name: "participations_created_by_type_null"

    change_column_null :rdvs, :created_by_type, false
    change_column_null :participations, :created_by_type, false

    remove_check_constraint :rdvs, name: "rdvs_created_by_type_null"
    remove_check_constraint :participations, name: "participations_created_by_type_null"
  end
end
