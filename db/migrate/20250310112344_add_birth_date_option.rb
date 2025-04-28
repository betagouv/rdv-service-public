class AddBirthDateOption < ActiveRecord::Migration[7.1]
  def change
    add_column :territories, :enable_birth_date_field, :boolean, default: false

    up_only do
      # Pour la rétro-compatibilité, on active l'option sur tous les territoires de l'instance historique
      if ENV["HOST"] == "https://www.rdv-solidarites.fr"
        Territory.update_all(enable_birth_date_field: true)
      end
    end
  end
end
