class Agents::InstanceMigrationsController < AgentAuthController
  layout "application_agent_config"

  # décommenter cette ligne quand on rendra cette page acessible via le menu
  # before_action { @active_agent_preferences_menu_item = :instance_migrations }

  def show
    skip_authorization
  end

  def oauth_callback
    skip_authorization
    redirect_to agents_instance_migration_path
  end

  private

  def pundit_user
    current_agent
  end
end
