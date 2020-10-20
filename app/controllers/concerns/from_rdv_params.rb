module FromRdvParams
  extend ActiveSupport::Concern

  def set_resources_from_rdv_params
    stored_location = session[:user_return_to]
    return if stored_location.blank? || Rails.application.routes.recognize_path(stored_location) != { controller: "users/rdv_wizard_steps", action: "new" }

    parsed = Rack::Utils.parse_nested_query(URI.parse(stored_location).query)
    @motif = Motif.find(parsed["motif_id"]) if parsed["motif_id"].present?
    @starts_at = Time.parse(parsed["starts_at"]) if parsed["starts_at"].present?
    @lieu = Lieu.find(parsed["lieu_id"]) if parsed["lieu_id"].present?
  end
end
