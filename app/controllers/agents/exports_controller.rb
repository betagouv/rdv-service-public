class Agents::ExportsController < AgentAuthController
  layout "application_agent_config"

  before_action { @active_agent_preferences_menu_item = :exports }

  def index
    @exports = policy_scope(Export)
      .recent
      .order(created_at: :desc)
  end

  def download
    export = Export.find(params[:export_id])
    authorize(export)
    send_data export.load_file, filename: export.file_name, type: "application/vnd.ms-excel"
  end

  private

  def pundit_user
    current_agent
  end
end
