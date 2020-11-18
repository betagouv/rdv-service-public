class Agents::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_action :prevent_if_upcoming_rdvs, only: [:destroy]

  def pundit_user
    AgentContext.new(current_agent)
  end

  def edit; end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_right_bar_with resource
    end
  end

  def destroy
    flash[:notice] = "Votre compte a été supprimé."
    current_agent.organisations.each { AgentRemoval.new(@agent, _1).remove! }
    current_agent.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    redirect_to root_path
  end


  private

  def prevent_if_upcoming_rdvs
    org_with_upcoming_rdvs = current_agent.organisations.all.find { AgentRemoval.new(@agent, _1).upcoming_rdvs? }
    return unless org_with_upcoming_rdvs

    flash[:error] = "Impossible de supprimer votre compte car vous avez des RDVs à venir dans l'organisation #{org_with_upcoming_rdvs.name}. Veuillez les supprimer ou les réaffecter avant de supprimer votre compte."
    redirect_to edit_agent_registration_path
  end

  def after_inactive_sign_up_path_for(_)
    new_agent_session_path
  end
end
