class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :log_params_to_sentry

  def microsoft_graph
    if current_agent.update(microsoft_graph_token: microsoft_graph_token, refresh_microsoft_graph_token: refresh_microsoft_graph_token)
      Outlook::MassCreateEventJob.perform_later(current_agent)
      flash[:success] = "Votre compte Outlook a bien été connecté"
    else
      flash[:alert] = "Votre compte Outlook n'a pas pu être connecté"
      Sentry.capture_message("Microsoft Graph OmniAuth failed for #{microsoft_graph_email}: #{request.env}", fingerprint: ["ms_graph_omniauth_failure"])
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
