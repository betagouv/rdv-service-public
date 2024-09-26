class CopyUsersBetweenOrganisationsService < BaseService
  def initialize(source_organisation_ids, target_organisation_id)
    @source_organisation_ids = source_organisation_ids
    @target_organisation_id = target_organisation_id
  end

  def perform
    target_organisation = Organisation.find_by(id: @target_organisation_id)
    unless target_organisation
      Rails.logger.error("Organisation cible introuvable avec l'ID #{@target_organisation_id}")
      return
    end

    source_organisations = Organisation.where(id: @source_organisation_ids)
    if source_organisations.empty?
      Rails.logger.error("Aucune organisation source valide trouvée.")
      return
    end

    users = User.joins(:organisations).where(organisations: { id: source_organisations.pluck(:id) }).distinct

    users.find_each do |user|
      user.add_organisation(target_organisation)
    end
  end
end
