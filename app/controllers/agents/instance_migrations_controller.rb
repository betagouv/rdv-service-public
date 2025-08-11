class Agents::InstanceMigrationsController < AgentAuthController
  layout "application_agent_config"

  # décommenter cette ligne quand on rendra cette page acessible via le menu
  # before_action { @active_agent_preferences_menu_item = :instance_migrations }

  def show
    skip_authorization
  end

  def oauth_callback
    skip_authorization

    credentials = request.env["omniauth.auth"].credentials
    instance_export = InstanceExport.create!(
      agent: current_agent,
      api_token: credentials.token,
      refresh_token: credentials.refresh_token
    )

    if current_agent.organisations.count != 1
      raise "on ne sait pas depuis organisation copier les usagers"
    end

    orgs = instance_export.new_instance_organisations
    if orgs.count != 1
      raise "on ne sait pas dans quelle organisation ajouter les usagers"
    end

    instance_export.update!(destination_organisation_id: orgs.first["id"])

    redirect_to agents_instance_migration_path
  end

  private

  def pundit_user
    current_agent
  end
end
