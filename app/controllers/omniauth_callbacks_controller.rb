class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def microsoft_graph
    if outlook_config.update(microsoft_graph_token: microsoft_graph_token, refresh_microsoft_graph_token: refresh_microsoft_graph_token)
      Outlook::MassCreateEventJob.perform_later(current_agent)
      flash[:success] = "Votre compte Outlook a bien été connecté"
    else
      flash[:alert] = "Votre compte Outlook n'a pas pu être connecté"
      Sentry.capture_message("Microsoft Graph OmniAuth failed for #{microsoft_graph_email}: #{request.env}", fingerprint: ["ms_graph_omniauth_failure"])
    end
    redirect_to agents_calendar_sync_outlook_sync_path
  end

  private

  def outlook_config
    current_agent.outlook_config || current_agent.build_outlook_config
  end

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
