# frozen_string_literal: true

module CanHaveRdvWizardContext
  extend ActiveSupport::Concern

  included do
    before_action :set_rdv_wizard_from_devise_return_path
  end

  def set_rdv_wizard_from_devise_return_path
    return if session[:user_return_to].blank?

    parsed_uri = URI.parse(session[:user_return_to])
    return if parsed_uri.path != "/users/rdv_wizard_step/new"

    parsed_params = Rack::Utils.parse_nested_query(parsed_uri.query).to_h.symbolize_keys
    return if %i[motif_id starts_at lieu_id].any? { parsed_params[_1].blank? }

    @rdv_wizard = UserRdvWizard::Step1.new(nil, parsed_params)
    return if @rdv_wizard.creneau.present?

    @rdv_wizard = nil
    session.delete(:user_return_to)
  end
end
