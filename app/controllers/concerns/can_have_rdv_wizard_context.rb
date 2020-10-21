module CanHaveRdvWizardContext
  extend ActiveSupport::Concern

  included do
    before_action :set_rdv_wizard_context_variables
  end

  def set_rdv_wizard_context_variables
    return if session[:user_return_to].blank?

    parsed_uri = URI.parse(session[:user_return_to])
    return if parsed_uri.path != "/users/rdv_wizard_step/new"

    parsed = Rack::Utils.parse_nested_query(parsed_uri.query)
    @motif = Motif.find(parsed["motif_id"]) if parsed["motif_id"].present?
    @starts_at = Time.parse(parsed["starts_at"]) if parsed["starts_at"].present?
    @lieu = Lieu.find(parsed["lieu_id"]) if parsed["lieu_id"].present?
  end
end
