class Agents::ExportsController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"

  before_action { @active_agent_preferences_menu_item = :exports }

  def index
    @exports = policy_scope(Export)
      .available
      .order(created_at: :desc)
      .select(Export.column_names - ["content"]) # Don't load large content from DB when we don't need it
  end

  def show
    export = Export.find(params[:id])
    authorize(export)
    send_data Base64.decode64(export.content), filename: export.file_name
  end

  private

  def pundit_user
    current_agent
  end
end
