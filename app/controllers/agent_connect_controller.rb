# Pour la doc d'Agent Connect: voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs.md#32-je-veux-savoir-comment-fonctionne-agentconnect-et-comment-identifierauthentifier-les-agents
class AgentConnectController < ApplicationController
  def auth
    auth_client = AgentConnectOpenIdClient::Auth.new(
      login_hint: params[:login_hint],
      client_id: current_domain.agent_connect_client_id,
      client_secret: current_domain.agent_connect_client_secret
    )

    connection_for = if params[:for_user]
                       "user"
                     elsif params[:for_super_admin]
                       "super_admin"
                     else
                       "agent"
                     end

    session[:pro_connect] = {
      state: auth_client.state,
      nonce: auth_client.nonce,
      connection_for:,
    }

    force_2fa = connection_for == "super_admin"

    redirect_to auth_client.redirect_url(agent_connect_callback_url, force_2fa:), allow_other_host: true
  end

  def callback
    pro_connect_session = session.delete(:pro_connect)

    unless pro_connect_session
      flash[:error] = generic_error_message
      redirect_to root_path
      return
    end

    pro_connect_session.symbolize_keys!

    callback_client = AgentConnectOpenIdClient::Callback.new(
      session_state: pro_connect_session[:state],
      params_state: params[:state],
      callback_url: agent_connect_callback_url,
      nonce: pro_connect_session[:nonce],
      client_id: current_domain.agent_connect_client_id,
      client_secret: current_domain.agent_connect_client_secret
    )

    if callback_client.fetch_user_info_from_code!(params[:code])

      case pro_connect_session[:connection_for]
      when "user"
        connect_user(callback_client)
      when "super_admin"
        if callback_client.went_through_2fa?
          connect_super_admin(callback_client)
        else
          flash[:error] = "Vous devez activer la double authentification sur votre compte ProConnect pour vous connecter en tant que super administrateur."
          redirect_to connexion_super_admins_path
        end
      when "agent"
        connect_agent(callback_client)
      else
        raise "Unknown connection_for #{pro_connect_session[:connection_for]}"
      end
    else
      flash[:error] = generic_error_message
      redirect_to(new_agent_session_path)
    end
  end

  private

  # Devise fournit un mécanisme `store_location_for` qui permet de revenir
  # vers le path demandé après le process de login.
  # Ce controller gère l'authentification, nous ne souhaitons donc
  # jamais revenir vers ses paths après un login.
  def storable_location?
    false
  end

  def connect_super_admin(callback_client)
    # Création d'un super admin en dev si aucun n'existe
    if Rails.env.development? && SuperAdmin.none?
      SuperAdmin.create!(email: callback_client.user_email, first_name: callback_client.user_first_name, last_name: callback_client.user_last_name, role: :legacy_admin)
    end

    super_admin = SuperAdmin.find_by(email: callback_client.user_email)

    if super_admin
      bypass_sign_in super_admin, scope: :super_admin

      session[:agent_connect_id_token] = callback_client.id_token_for_logout
      redirect_to super_admins_agents_path
    else
      flash[:error] = "Compte ProConnect non autorisé"
      redirect_to connexion_super_admins_path
    end
  end

  def connect_user(callback_client)
    user = User.find_or_initialize_by(pro_connect_openid_sub: callback_client.openid_sub)

    user.confirmed_at ||= Time.zone.now # Nécessaire pour que Devise autorise la connexion
    user.update!(
      first_name: callback_client.user_first_name,
      last_name: callback_client.user_last_name,
      notification_email: callback_client.user_email
    )

    bypass_sign_in(user, scope: :user)
    session[:agent_connect_id_token] = callback_client.id_token_for_logout
    redirect_to after_sign_in_path_for(user)
  end

  def connect_agent(callback_client)
    # Agent Connect recommande de faire la réconciliation sur l'email et non pas sur le sub
    # voir https://github.com/numerique-gouv/agentconnect-documentation/blob/main/doc_fs/donnees_fournies.md#le-champ-sub
    agent = Agent.active.find_by(email: callback_client.user_email)

    if current_domain.allow_self_onboarding
      agent ||= Agent.new(email: callback_client.user_email, password: SecureRandom.base64(32))
    end

    if agent
      agent.update!(
        connected_with_agent_connect: true,
        first_name: callback_client.user_first_name,
        last_name: callback_client.user_last_name,
        proconnect_siret: callback_client.user_siret,
        invitation_token: nil, # Pour désactiver les anciens liens d'invitation
        invitation_accepted_at: agent.invitation_accepted_at || Time.zone.now,
        confirmed_at: agent.confirmed_at || Time.zone.now,
        last_sign_in_at: Time.zone.now
      )

      bypass_sign_in agent, scope: :agent
      session[:agent_connect_id_token] = callback_client.id_token_for_logout
      redirect_to after_sign_in_path_for(agent)
    else
      # On pourrait améliorer le cas d'erreur décrit dans https://github.com/betagouv/rdv-service-public/issues/4360
      flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{callback_client.user_email}.<br />" \
                      "Vous devez utiliser ProConnect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />" \
                      "Vous pouvez également contacter le support à l'adresse <a href='mailto:#{current_domain.support_email}'>#{current_domain.support_email}</a> si le problème persiste."
      redirect_to new_agent_session_path
    end
  end

  def generic_error_message
    support_email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{support_email}">#{support_email}</a> si le problème persiste.)
  end
end
