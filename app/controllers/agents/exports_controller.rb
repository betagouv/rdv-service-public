class Agents::ExportsController < AgentAuthController
  layout "application_agent_config"

  before_action { @active_agent_preferences_menu_item = :exports }

  def index
    @exports = policy_scope(Export, policy_scope_class: Agent::ExportPolicy::Scope)
      .recent
      .order(created_at: :desc)
  end

  def download
    export = Export.find(params[:export_id])
    authorize(export, policy_class: Agent::ExportPolicy)

    return redirect_to_two_factor_verification unless recent_two_factor_authentication?

    send_data export.load_file, filename: export.file_name, type: "application/vnd.ms-excel"
  end

  private

  # Un super admin usurpant un agent n'a accès ni à sa boîte mail, ni à son compte ProConnect : lui
  # demander le 2FA de l'agent le bloquerait. Sa propre connexion en tant que super admin a déjà
  # nécessité un 2FA récent (cf. `ProConnectController#connect_super_admin`) et sa session est bornée
  # dans le temps (cf. le timeout Devise sur les sessions SuperAdmin), donc on peut l'exempter ici.
  # Idéalement on rajoutera la vérification du 2FA récent du SuperAdmin dans un second temps.
  def recent_two_factor_authentication?
    session[:super_admin_signed_in_as_agent] || AgentTwoFactorSessionState.fresh?(session)
  end

  def redirect_to_two_factor_verification
    AgentTwoFactorSessionState.store_return_to!(session, request.fullpath)
    redirect_to new_agents_two_factor_verification_path
  end

  def pundit_user
    current_agent
  end
end
