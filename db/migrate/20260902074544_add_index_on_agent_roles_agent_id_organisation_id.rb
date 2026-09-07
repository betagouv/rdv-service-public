class AddIndexOnAgentRolesAgentIdOrganisationId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # ceci est un covering index, il permet donc de récupérer la liste des orgas d'un agent via un "Index-Only Scan"
    add_index :agent_roles, %i[agent_id organisation_id], include: %i[access_level agent_accueil], unique: true, algorithm: :concurrently
    add_index :agent_roles, :organisation_id, algorithm: :concurrently

    # devient inutile avec l'ajout de l'index ci-dessus
    remove_index :agent_roles, :agent_id, algorithm: :concurrently
    remove_index :agent_roles, :access_level, algorithm: :concurrently
    remove_index :agent_roles, %i[organisation_id agent_id], unique: true, algorithm: :concurrently
  end
end
