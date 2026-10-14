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

    return redirect_to_two_factor_verification unless AgentTwoFactorSessionState.recent_2fa?(session)

    send_data export.load_file, filename: export.file_name, type: "application/vnd.ms-excel"
  end

  private

  # Un fichier envoyé via `send_data` ne remplace pas la page affichée par le navigateur (pas de
  # rendu HTML) : rediriger directement vers le lien de téléchargement laisserait l'agent sur la page
  # de vérification du code, sans retour visuel. On renvoie donc vers la liste des exports, où l'agent
  # peut relancer lui-même le téléchargement.
  def redirect_to_two_factor_verification
    AgentTwoFactorSessionState.store_return_to!(session, agents_exports_path)
    redirect_to new_agents_two_factor_verification_path
  end

  def pundit_user
    current_agent
  end
end
