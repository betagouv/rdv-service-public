# Le guide pour configurer ProConnect en local : docs/interconnexions/proconnect.md

class ProConnectController < ApplicationController
  def auth
    auth_client = ProConnectOpenIdClient::Auth.new(
      login_hint: params[:login_hint],
      client_id: current_domain.pro_connect_client_id,
      client_secret: current_domain.pro_connect_client_secret
    )

    connection_for = params[:user_type]

    session[:pro_connect] = {
      state: auth_client.state,
      nonce: auth_client.nonce,
      connection_for:,
    }

    force_2fa = %w[super_admin operator_manager].include?(connection_for)

    redirect_to auth_client.redirect_url(pro_connect_callback_url, force_2fa:), allow_other_host: true
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def callback
    if params[:error] == "server_error"
      flash[:error] = "L'authentification a échoué en raison d'une erreur côté ProConnect. Nous vous invitons à contacter leur support."
      redirect_to root_path and return
    end

    pro_connect_session = session.delete(:pro_connect)
    unless pro_connect_session
      flash[:error] = generic_error_message
      redirect_to root_path and return
    end

    pro_connect_session.symbolize_keys!

    callback_client = ProConnectOpenIdClient::Callback.new(
      session_state: pro_connect_session[:state],
      params_state: params[:state],
      callback_url: pro_connect_callback_url,
      nonce: pro_connect_session[:nonce],
      client_id: current_domain.pro_connect_client_id,
      client_secret: current_domain.pro_connect_client_secret
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
      when "operator_manager"
        if callback_client.went_through_2fa?
          connect_operator_manager(callback_client)
        else
          flash[:error] = "Vous devez activer la double authentification sur votre compte ProConnect pour vous connecter en tant que gestionnaire d'opérateurs."
          redirect_to operators_root_path
        end
      when "agent"
        connect_agent(callback_client)
      else
        Sentry.capture_message("Unknown connection_for: #{pro_connect_session[:connection_for].inspect}", extra: { session: session.to_h, pro_connect_session: })
        flash[:error] = generic_error_message
        redirect_to(new_agent_session_path)
      end
    else
      flash[:error] = generic_error_message
      redirect_to(new_agent_session_path)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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

    super_admin_return_to = session.delete(:super_admin_return_to)

    super_admin = SuperAdmin.find_by(email: callback_client.user_email)

    if super_admin
      bypass_sign_in super_admin, scope: :super_admin

      session[:pro_connect_id_token] = callback_client.id_token_for_logout
      redirect_to super_admin_return_to || super_admins_agents_path
    else
      flash[:error] = "Compte ProConnect non autorisé"
      redirect_to connexion_super_admins_path
    end
  end

  def connect_operator_manager(callback_client)
    operator_manager = OperatorManager.find_by(email: callback_client.user_email)

    if operator_manager
      bypass_sign_in operator_manager, scope: :operator_manager

      session[:pro_connect_id_token] = callback_client.id_token_for_logout

      operator_manager.update(pro_connect_openid_sub: callback_client.openid_sub)
    else
      flash[:error] = "Compte ProConnect non autorisé"
    end

    redirect_to operators_root_path
  end

  def connect_user(callback_client)
    user = User.find_or_initialize_by(pro_connect_openid_sub: callback_client.openid_sub)

    user.latest_login_at ||= Time.zone.now
    user.update!(
      first_name: callback_client.user_first_name,
      last_name: callback_client.user_last_name,
      notification_email: callback_client.user_email
    )

    bypass_sign_in(user, scope: :user)
    session[:pro_connect_id_token] = callback_client.id_token_for_logout
    redirect_to after_sign_in_path_for(user)
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def connect_agent(callback_client)
    sub = callback_client.openid_sub
    agent_by_sub = Agent.active.find_by(pro_connect_openid_sub: sub)
    agent_by_email = Agent.active.find_by(email: callback_client.user_email)
    Sentry.set_user({ email: callback_client.user_email })

    # On trouve un agent vie le sub, et un autre agent via l'e-mail
    if agent_by_email && agent_by_sub && agent_by_email != agent_by_sub
      error_message = <<~ERROR
        Il existe deux comptes correspondant : #{agent_by_email.email} et #{agent_by_sub.email}.
        Nous vous invitons à #{link_to_demande_support('contacter le support', callback_client)}.
      ERROR
      Sentry.capture_message(error_message, extra: { user_info: callback_client.user_info })
      flash[:error] = error_message
      redirect_to new_agent_session_path and return
    end

    # On ne trouve un agent que par e-mail et cet agent porte un autre sub.
    if !agent_by_sub && agent_by_email&.pro_connect_openid_sub && agent_by_email.pro_connect_openid_sub != sub
      extra = { user_info: callback_client.user_info, old_sub: agent_by_email.pro_connect_openid_sub }
      Sentry.capture_message("Réconciliation ProConnect via e-mail, sub existant écrasé", extra:)
    end

    agent = agent_by_sub || agent_by_email

    if agent.nil?
      if current_domain.allow_self_onboarding
        agent ||= Agent.new(email: callback_client.user_email, password: SecureRandom.base64(32))
      else
        # On pourrait améliorer le cas d'erreur décrit dans https://github.com/betagouv/rdv-service-public/issues/4360
        flash[:error] = <<~ERROR
          Il n'y a pas de compte agent pour l'adresse mail #{callback_client.user_email}.<br />
          Vous devez utiliser ProConnect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />
          Vous pouvez également #{link_to_demande_support('contacter le support', callback_client)} si le problème persiste.
        ERROR
        redirect_to new_agent_session_path and return
      end
    end

    if agent.email != callback_client.user_email
      flash[:info] = "Note : votre adresse e-mail a été mise à jour depuis ProConnect. Ancienne adresse : #{agent.email}, nouvelle adresse : #{callback_client.user_email}"
    end

    agent.assign_attributes(
      pro_connect_openid_sub: sub,
      email: callback_client.user_email,
      first_name: callback_client.user_first_name,
      last_name: callback_client.user_last_name,
      proconnect_siret: callback_client.user_siret,
      pro_connect_idp_id: callback_client.user_idp_id,
      pro_connect_2fa_active: callback_client.went_through_2fa?,
      invitation_token: nil, # Pour désactiver les anciens liens d'invitation
      invitation_accepted_at: agent.invitation_accepted_at || Time.zone.now,
      confirmed_at: agent.confirmed_at || Time.zone.now,
      last_sign_in_at: Time.zone.now
    )
    agent.skip_reconfirmation!
    agent.save!

    bypass_sign_in agent, scope: :agent
    session[:pro_connect_id_token] = callback_client.id_token_for_logout
    redirect_to after_sign_in_path_for(agent)
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  def generic_error_message
    support_link = new_aide_demande_support_path(role: "agent", sujet: "Connexion ProConnect")
    %(Nous n'avons pas pu vous authentifier. #{view_context.link_to('Contactez le support', support_link, class: 'fr-link')} si le problème persiste.)
  end

  def link_to_demande_support(name, callback_client)
    view_context.link_to(
      name,
      new_aide_demande_support_path(
        role: "agent",
        sujet: "Réconciliation ProConnect",
        email: callback_client.user_email,
        first_name: callback_client.user_first_name,
        last_name: callback_client.user_last_name
      ),
      class: "fr-link"
    )
  end
end
