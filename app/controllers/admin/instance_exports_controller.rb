class Admin::InstanceExportsController < AgentAuthController
  before_action { redirect_to(root_path) unless current_domain == Domain::RDV_AIDE_NUMERIQUE }

  def index
    @exports = policy_scope(InstanceExport, policy_scope_class: Agent::InstanceExportPolicy::Scope)
  end

  def new
    skip_authorization
    session[:instance_export_source_organisation_id] = current_organisation.id
  end

  def oauth_callback
    credentials = request.env["omniauth.auth"].credentials
    instance_export = InstanceExport.create!(
      agent: current_agent,
      api_token: credentials.token,
      refresh_token: credentials.refresh_token,
      source_organisation_id: session[:instance_export_source_organisation_id]
    )
    authorize(instance_export, :create?, policy_class: Agent::InstanceExportPolicy)

    flash[:success] = "Connexion à RDV Service Public réussie"
    redirect_to edit_admin_organisation_instance_export_path(current_agent.organisations.first, instance_export.id)
  end

  def edit
    @instance_export = find_instance_export
  end

  def update
    @instance_export = find_instance_export

    destination_organisation_id = params[:destination_organisation_id]

    if destination_organisation_id.blank?
      @instance_export.create_organisation_on_new_instance!
    else
      @instance_export.update!(params.permit(:destination_organisation_id))
    end

    @instance_export.copy_to_new_instance!(current_domain)
    redirect_to admin_organisation_instance_export_path(current_organisation, @instance_export.id)
  end

  def show
    @instance_export = find_instance_export
  end

  private

  def find_instance_export
    InstanceExport.find(params[:id]).tap do |export|
      authorize(export, policy_class: Agent::InstanceExportPolicy)
    end
  end

  def pundit_user
    current_agent
  end
end
