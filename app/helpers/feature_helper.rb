module FeatureHelper
  def show_agent_prescription_feature?
    current_organisation.territory.departement_number.in?(%w[83]) || Rails.env.development? || ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
  end
end
