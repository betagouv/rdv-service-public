# frozen_string_literal: true

# rails runner scripts/migrate_cnfs_to_different_organisations.rb
# rubocop:disable Rails/SkipsModelValidations

old_organisation = Organisation.find(340)

agent_ids_by_organisation_id = {
  347 => [5975], # Médiathèque Jean Carmin
  348 => [5983], # La Bâtie-Neuve
  349 => [5976, 5977, 5978], # Grand Cognac
  350 => [5982], # Espace de la porte St Jacques, Troyes
  351 => [5974], # France Services Thenon
  352 => [5981], # Tremblay-en-France
}

class MotifsPlageOuverture < ApplicationRecord
end

ActiveRecord::Base.transaction do
  agent_ids_by_organisation_id.each do |organisation_id, agent_ids|
    new_organisation = Organisation.find(organisation_id)

    # migrer les plages d'ouverture
    plage_ouvertures_for_organisation = PlageOuverture.where(agent_id: agent_ids)
    plage_ouvertures_for_organisation.where(organisation: old_organisation).update_all(organisation_id: new_organisation.id)

    # creer des duplicatas de motifs, et y associer les plages d'ouvertures, et les rdvs
    Motif.joins(rdvs: :agents_rdvs).where(agents_rdvs: { agent_id: agent_ids }).find_each do |old_motif|
      new_motif = old_motif.dup
      new_motif.organisation = new_organisation
      new_motif.save

      MotifsPlageOuverture.where(motif_id: old_motif, plage_ouverture_id: plage_ouvertures_for_organisation).update_all(motif_id: new_motif.id)

      Rdv.joins(:agents_rdvs).where(agents_rdvs: { agent_id: agent_ids }, motif: old_motif).update_all(motif_id: new_motif.id)
    end

    # migrer les rdv dans les nouveaux
    Rdv.joins(:agents_rdvs).where(agents_rdvs: { agent_id: agent_ids }).update_all(organisation_id: new_organisation.id)

    # migrer les lieux (en espérant qu'il n'y ai pas de lieux utilisés par plusieurs organisations différentes)
    Lieu.joins(rdvs: :agents_rdvs).where(agents_rdvs: { agent_id: agent_ids }).where(organisation: old_organisation).update_all(organisation_id: new_organisation.id)

    # migrer les absence
    Absence.where(agent_id: agent_ids).where(organisation: old_organisation).update_all(organisation_id: new_organisation.id)

    # et ajouter les usagers
    User.joins(rdvs_users: { rdv: :agents_rdvs }).where(agents_rdvs: { agent_id: agent_ids }).find_each do |user|
      user.add_organisation(new_organisation)
    end
  end

  # Des lieux supplémentaires ont été créés pour le grand cognac
  Lieu.where("address LIKE '%16, Charente, Nouvelle-Aquitaine'").where(organisation: old_organisation).update_all(organisation_id: 349)
end

# rubocop:enable Rails/SkipsModelValidations
