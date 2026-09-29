class AddAmiEnabledToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :ami_enabled, :boolean, default: false, null: false

    change_column_comment :organisations, :ami_enabled, from: nil, to: <<~COMMENT
      Active le suivi des rendez-vous via l'Application Mobile Interministérielle (AMI)
    COMMENT
  end
end
