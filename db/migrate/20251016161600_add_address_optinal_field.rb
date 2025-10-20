class AddAddressOptinalField < ActiveRecord::Migration[7.2]
  def change
    add_column :territories, :enable_address_field, :boolean, default: false

    up_only do
      # Historiquement, le champ adresse n’était affiché que sur RDV Solidarités/RDV Aide Numérique
      # On active donc ce champ pour tous les espaces existants de l’instance historique.
      if ENV.fetch("HOST", nil) == "https://www.rdv-solidarites.fr"
        Territory.update_all(enable_address_field: true)
      end
    end
  end
end
