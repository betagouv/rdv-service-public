module CurrentOrganisation
  extend ActiveSupport::Concern

  included do
    before_action :set_session_organisation_id, :set_current_organisation
  end

  def set_session_organisation_id
    return if params[:organisation_id].nil?

    session[:organisation_id] = params[:organisation_id]
  end

  def set_current_organisation
    Current.organisation ||= Organisation.find(session[:organisation_id])
  end
end
