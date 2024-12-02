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
    rdv_wizard = UserRdvWizard::Step1.new(nil, parsed_params)
    # L'usager doit être connecté afin de voir les créneaux pour un motif de Follow Up
    return if rdv_wizard.motif&.follow_up?

    if rdv_wizard.creneau.blank?
      session.delete(:user_return_to)
      return
    end

    @rdv_wizard = rdv_wizard
  rescue ArgumentError => e
    # on a des erreurs sur la recherche de créneau et j’aimerais avoir plus de contexte pour comprendre ce qui se passe
    # https://sentry.incubateur.net/organizations/betagouv/issues/108784
    Sentry.set_context(:rdv_wizard_context, { user_return_to: session[:user_return_to] })
    Sentry.capture_exception(e)
  end
end
