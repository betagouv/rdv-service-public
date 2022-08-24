# frozen_string_literal: true

class AddNewDomainToOrganisationsForBeta < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :new_domain_beta, :boolean, default: false, null: false,
                                                           comment: "en mettant ce boolean a true, on active l'utilisation du nouveau domaine pour les conseillers numeriques de cette organisation"
  end
end
