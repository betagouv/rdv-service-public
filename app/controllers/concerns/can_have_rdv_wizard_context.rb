module CanHaveRdvWizardContext
  extend ActiveSupport::Concern

  included do
    before_action :set_rdv_wizard_from_devise_return_path
    before_action :redirect_if_creneau_unavailable
  end

  def set_rdv_wizard_from_devise_return_path
    @rdv_wizard = rdv_wizard_from_session if rdv_wizard_from_session&.creneau.present?
  end

  def redirect_if_creneau_unavailable
    return unless rdv_wizard_from_session
    return if rdv_wizard_from_session.creneau.present?

    session.delete(:user_return_to)
    redirect_to(
      prendre_rdv_path(rdv_wizard_from_session.to_query),
      flash: { error: "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre ou refaire votre recherche ultérieurement." }
    )
  end

  private

  def rdv_wizard_from_session
    return @rdv_wizard_from_session if instance_variable_defined?(:@rdv_wizard_from_session)

    @rdv_wizard_from_session = begin
      return if session[:user_return_to].blank?

      parsed_uri = URI.parse(session[:user_return_to])
      return unless parsed_uri.path == "/users/rdv_wizard_step/new"

      parsed_params = Rack::Utils.parse_nested_query(parsed_uri.query).to_h.symbolize_keys
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "parsed_params", data: { parsed_params:, ip: request.remote_ip }))
      rdv_wizard = Users::RdvBuilder.new(nil, parsed_params)
      # L'usager doit être connecté afin de voir les créneaux pour un motif de Follow Up
      return if rdv_wizard.motif&.follow_up?

      rdv_wizard
    rescue ArgumentError => e
      # on a des erreurs sur la recherche de créneau et j'aimerais avoir plus de contexte pour comprendre ce qui se passe
      # https://sentry.incubateur.net/organizations/betagouv/issues/108784
      Sentry.set_context(:rdv_wizard_context, { user_return_to: session[:user_return_to] })
      Sentry.capture_exception(e)
      nil
    end
  end
end
