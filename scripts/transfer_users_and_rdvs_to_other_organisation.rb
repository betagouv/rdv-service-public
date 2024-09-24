# Ce script permet de transférer les usagers et les rendez-vous d'une organisation source et d'une liste de motifs cible
# au même motif dans l'organisation cible.
# Example:
# load "scripts/transfer_users_and_rdvs_to_other_organisation.rb"; TransferUsersAndRdvsToOtherOrganisation.new(1, 1, [1]).call

class TransferUsersAndRdvsToOtherOrganisation
  attr_reader :source_organisation, :target_organisation, :motifs

  def initialize(source_organisation_id:, target_organisation_id:, motif_ids:)
    @source_organisation = Organisation.find(source_organisation_id)
    @target_organisation = Organisation.find(target_organisation_id)
    @motifs = Motif.where(id: motif_ids)
  end

  def call
    ActiveRecord::Base.transaction do
      transfer_rdvs
      remove_users_from_source_organisation
      add_users_to_target_organisation
    end
  end

  private

  def transfer_rdvs
    Rdv.joins(:participations).where(
      motif_id: motifs.ids,
      organisation: source_organisation,
      participations: { user: users_to_transfer }
    ).find_each do |rdv|
      rdv.update!(organisation_id: target_organisation.id)
    end
  end

  def remove_users_from_source_organisation
    source_organisation.users.delete(users_to_transfer)
  end

  def add_users_to_target_organisation
    users_to_transfer.each do |user|
      user.add_organisation(target_organisation)
    end
  end

  def users_to_transfer
    @users_to_transfer ||= User
      .distinct
      .joins(:organisations, :rdvs)
      .where(organisations: source_organisation)
      .where(rdvs: { motif_id: motifs.ids })
      .to_a
  end
end
