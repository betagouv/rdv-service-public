class AddRdvPlanDossierUrl < ActiveRecord::Migration[7.1]
  def change
    add_column :rdv_plans, :dossier_url, :text
  end
end
