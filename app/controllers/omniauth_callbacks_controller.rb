# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :log_params_to_sentry

  def franceconnect
    upsert_service = UpsertUserForFranceconnectService
      .perform_with(request.env["omniauth.auth"]["info"])

    flash[:success] = upsert_service.new_user? ? "Votre compte a été créé" : "Vous êtes connecté·e"
    bypass_sign_in upsert_service.user, scope: :user
    session[:connected_with_franceconnect] = true
    redirect_to after_sign_in_path_for(upsert_service.user)
  end

  def github
    email = request.env["omniauth.auth"]["info"]["email"]

    # Automatically create the first SuperAdmin in development
    SuperAdmin.create!(email: email) if Rails.env.development? && SuperAdmin.none?

    super_admin = SuperAdmin.find_by(email: email)
    if super_admin.present?
      bypass_sign_in super_admin, scope: :super_admin
      redirect_to super_admins_agents_path
    else
      flash[:alert] = "Compte GitHub non autorisé"
      Rails.logger.error("OmniAuth failed for #{email}")
      redirect_to root_path
    end
  end

  def microsoft_graph
    if current_agent.update(microsoft_graph_token: microsoft_graph_token, refresh_microsoft_graph_token: refresh_microsoft_graph_token)
      Outlook::MassCreateEventJob.perform_later(current_agent)
      flash[:notice] = "Votre compte Outlook a bien été connecté"
    else
      flash[:alert] = "Votre compte Outlook n'a pas pu être connecté"
      Sentry.capture_message("Microsoft Graph OmniAuth failed for #{microsoft_graph_email}: #{request.env}")
    end
    redirect_to agents_calendar_sync_outlook_sync_path
  end

  private

  def microsoft_graph_email
    request.env.dig("omniauth.auth", "extra", "raw_info", "user_principal_name")
  end

  def refresh_microsoft_graph_token
    request.env.dig("omniauth.auth", "credentials", "refresh_token")
  end

  def microsoft_graph_token
    request.env.dig("omniauth.auth", "credentials", "token")
  end
end
