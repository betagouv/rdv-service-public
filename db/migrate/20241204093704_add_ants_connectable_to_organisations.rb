class AddAntsConnectableToOrganisations < ActiveRecord::Migration[7.1]
  def change
    add_column :organisations, :ants_connectable, :boolean, null: false, default: false

    change_column_comment :organisations, :ants_connectable, from: nil, to: <<~COMMENT
      Autorise l'organisation à être branchée sur le moteur de recherche de l'ANTS sur https://rendezvouspasseport.ants.gouv.fr/. Pour éviter de brancher n'importe qui sur ce moteur de recherche, cette option n'est pas activable par les agents.
    COMMENT

    up_only do
      mairies_territory = Territory.find_by(name: "Mairies")
      if mairies_territory # La migration tourne aussi sur l'instance historique qui n'a pas ce territoire
        Organisation.where(territory_id: mairies_territory.id).update_all(ants_connectable: true)
      end
    end
  end
end
