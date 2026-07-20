class Agents::VisioNumeriqueController < AgentAuthController
  layout "application_agent_config"

  def show
    skip_authorization

    @access_token_present = session[:pro_connect_access_token].present?
  end

  def create_room
    skip_authorization

    access_token = session[:pro_connect_access_token]

    if access_token.blank?
      redirect_to agents_visio_numerique_path, alert: "Vous devez vous connecter via ProConnect pour utiliser cette fonctionnalité."
      return
    end

    result = VisioNumerique::CreateRoom.new(access_token:).call
    @room_url = result["url"]
    render :show
  rescue VisioNumerique::CreateRoom::ApiError => e
    redirect_to agents_visio_numerique_path, alert: "Erreur lors de la création de la salle : #{e.message}"
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
