module FeatureHelper
  # Prescription

  def show_agent_prescription_feature?(user_provided:)
    # TODO: faire sauter ce return une fois que nous avons implémenté la saisie d'adresse
    return false if current_organisation.territory.sectorized? && !user_provided
    return false unless current_organisation.territory.any_motifs_opened_for_prescription?

    true
  end

  def show_agent_prescription_incitation?
    current_agent.present? && current_agent.territories.any?(&:any_motifs_opened_for_prescription?)
  end

  def current_agent_can_prescribe_in_territory?(territory)
    current_agent.territories.include?(territory) && territory.any_motifs_opened_for_prescription?
  end

  def current_agent_first_organisation_in_territory(territory)
    current_agent.organisations.find_by(territory: territory)
  end
end
