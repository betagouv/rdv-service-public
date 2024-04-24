module FeatureHelper
  def show_agent_prescription_feature?(user_provided:)
    # TODO: faire sauter ce return une fois que nous avons implémenté la saisie d'adresse
    return false if current_organisation.territory.sectorized? && !user_provided
    return false unless current_organisation.territory.any_motifs_opened_for_prescription?

    true
  end

  def show_agent_prescription_incitation?
    current_agent.present? && current_agent.territories_through_organisations.any?(&:any_motifs_opened_for_prescription?)
  end
end
