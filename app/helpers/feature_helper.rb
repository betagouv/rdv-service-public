module FeatureHelper
  def show_agent_prescription_feature?(user_provided:)
    # TODO: faire sauter ce return une fois que nous avons implémenté la saisie d'adresse
    return false if current_organisation.territory.sectorized? && !user_provided

    current_organisation.territory.name.starts_with?("CDAD") ||
      current_organisation.territory.departement_number.in?(%w[83 26]) ||
      Rails.env.development? ||
      ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
  end
end
