class Agents::SessionsController < Devise::SessionsController
  include Admin::WeakPasswordControllerConcern

  # Lorsqu'un agent est connecté à une application Oauth via notre application,
  # Il est possible qu'il cherche à se déconnecter alors que sa session a déjà expiré.
  #
  # Dans ce cas, pour éviter que Devise retourne l'erreur "sessions.already_signed_out",
  # on évite de run le callback de Devise qui vérifie si l'agent est déjà déconnecté.
  #
  # De cette façon c'est nous qui gérons la redirection le cas échéant.
  skip_before_action :verify_signed_out_user, only: :destroy

  def new
    # Le flash d'erreur est trop agressif pour le cas d'un agent non connecté.
    # Un flash de style info est plus adapté.
    if flash[:alert] == I18n.t("devise.failure.unauthenticated")
      # Contrairement aux usagers, les agents ne peuvent pas créer de compte
      # On n'utilise donc pas `I18n.t("devise.failure.unauthenticated")`, mais une variante
      # Il faut utiliser un flash.now pour éviter de réafficher le flash après la connexion si on utilise ProConnect
      flash.now[:notice] = "Vous devez vous connecter pour continuer"
      flash[:alert] = nil
    end

    super
  end

  def create
    # this is the first line of Devise::SessionsController#create
    self.resource = warden.authenticate!(auth_options)

    if resource.pro_connect_openid_sub.present?
      sign_out(resource)
      redirect_to new_agent_session_path(pro_connect_required: resource.email)
      return
    end

    return if reset_current_agent_password_if_weak!(params[:agent][:password])

    if resource.sensitive_account?
      sign_out(resource)
      session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY] = resource.id
      Agents::LoginCodeSender.perform(email: resource.email, domain_id: current_domain.id)
      redirect_to new_agents_sessions_by_code_path
      return
    end

    if should_redirect_to_domain_etat?(current_domain, resource.organisations)
      redirect_to redirect_target_url_in_domain_etat, allow_other_host: true
      return
    end

    super
    # super will repeat warden.authenticate! which will not repeat everything but fetch from the session
    # cf https://github.com/wardencommunity/warden/blob/master/lib/warden/proxy.rb#L332-L334
  end

  def destroy
    # oauth_client_app_id est le paramètre passé par une application OAuth cliente depuis laquelle
    # l'agent vient de se déconnecter.
    # Si ce paramètre est présent, on veut déconnecter l'agent de notre application
    # (parfois en faisant aussi une déconnexion à ProConnect) puis le rediriger vers
    # l'application cliente, depuis laquelle il a commencé la déconnexion.
    #
    # Dans le cas où on le déconnecte d'abord de ProConnect, on est obligés de faire la redirection
    # vers l'appli cliente après avoir été redirigés vers notre root_url par ProConnect.
    if params[:oauth_client_app_id].present?
      oauth_app = Doorkeeper::Application.find_by(uid: params[:oauth_client_app_id])
      @oauth_client_app_post_logout_redirect_url = oauth_app.post_logout_redirect_uri
    end

    pro_connect_id_token = session.delete(:pro_connect_id_token)

    sign_out(:agent)

    # Si on redirige vers l'app cliente, on n'aura pas de render pendant lequel le flash s'affichera, donc on ne l'ajoute pas.
    if @oauth_client_app_post_logout_redirect_url
      # On est obligés de modifier la session ici puisque l'appel à `sign_out(:agent)` a effacé la session
      session[:post_logout_redirect_url] = @oauth_client_app_post_logout_redirect_url
    else
      set_flash_message!(:notice, :signed_out)
    end

    if session[:super_admin_signed_in_as_agent]
      session.delete(:super_admin_signed_in_as_agent)
      redirect_to super_admins_agents_path
    elsif pro_connect_id_token
      pro_connect_client = ProConnectOpenIdClient::Logout.new(pro_connect_id_token)

      redirect_to pro_connect_client.pro_connect_logout_url(root_url), allow_other_host: true
    else
      redirect_to after_sign_out_path_for(:agent)
    end
  end

  private

  def should_redirect_to_domain_etat?(current_domain, agent_organisations)
    current_domain == Domain::RDV_SERVICE_PUBLIC &&
      agent_organisations.exists? &&
      agent_organisations.all?(&:rdv_etat?)
  end

  def redirect_target_url_in_domain_etat
    stored_path = stored_location_for(:agent)
    if stored_path
      # on réécrit manuellement l’URL car on souhaite garder les query params du stored_path
      add_query_string_params_to_url(
        "#{request.protocol}#{Domain::RDV_SERVICE_PUBLIC_ETAT.host_name}#{stored_path}",
        automatic_redirection_from_rdvsp_anct: "1"
      )
    else
      # On veut renvoyer vers l'URL post-connexion pour les agents par défaut (authenticated_agent_root_url)
      # Comme elle a été définie à '/' on a du en redéfinir une explicite qui ne peut pas être confondue avec
      # une route non-authentifiée
      unauthenticated_explicit_agent_root_url(
        host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name,
        automatic_redirection_from_rdvsp_anct: "1"
      )
    end
  end
end
