module Admin::AuthenticatedControllerConcern
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

    before_action :set_flash_automatic_redirection_from_other_domain
    before_action :authenticate_agent_with_silent_proconnect_login!
    before_action :set_paper_trail_whodunnit
  end

  protected

  def user_for_paper_trail
    if current_super_admin.present?
      current_super_admin.name_for_paper_trail(impersonated: current_agent)
    else
      current_agent.name_for_paper_trail
    end
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default

    if request.referer.present? &&
       request.original_url != request.referer && # évite les boucles infinies
       URI.parse(request.referer).host == current_domain.host_name # évite de rediriger vers l'extérieur
      redirect_to request.referer
    else
      redirect_to authenticated_agent_root_url
    end
  end

  def set_flash_automatic_redirection_from_other_domain
    return if params[:automatic_redirection_from_other_domain] != "1"

    flash[:notice] = if current_domain == Domain::RDV_SERVICE_PUBLIC_ETAT
                       "Vous avez été automatiquement redirigé·e vers le domaine RDV Service Public pour les agents de l'État."
                     else
                       "Vous avez été automatiquement redirigé·e vers le domaine RDV Service Public pour les agents des collectivités."
                     end
  end
end
