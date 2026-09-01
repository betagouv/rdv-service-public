class Agents::ExportsController < AgentAuthController
  include Agents::TwoFactorFreshnessConcern

  layout "application_agent_config"

  before_action { @active_agent_preferences_menu_item = :exports }
  before_action :require_recent_two_factor_authentication!, only: :download

  def index
    @exports = policy_scope(Export, policy_scope_class: Agent::ExportPolicy::Scope)
      .recent
      .order(created_at: :desc)

    # Après une revérification du 2FA avant un téléchargement, on relance celui-ci automatiquement
    # une fois revenu sur cette page (voir Agents::TwoFactorFreshnessConcern#redirect_after_two_factor_verification!).
    @auto_download_export = @exports.find_by(id: params[:auto_download_export_id]) if params[:auto_download_export_id].present?
  end

  def download
    export = Export.find(params[:export_id])
    authorize(export, policy_class: Agent::ExportPolicy)
    send_data export.load_file, filename: export.file_name, type: "application/vnd.ms-excel"
  end

  private

  def pundit_user
    current_agent
  end
end
