class Agents::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_action { @current_agent_settings_menu_entry = :compte }

  def pundit_user
    AgentContext.new(current_agent)
  end

  def destroy
    removal_services = current_agent.organisations.map { AgentRemoval.new(@agent, _1) }
    if removal_services.all?(&:valid?)
      removal_services.each(&:remove!)
      flash[:notice] = I18n.t("devise.failure.deleted_account")
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      redirect_to root_path
    else
      flash[:error] = removal_services.select(&:invalid?).map { |service| service.errors.full_messages.join }.join(", ")
      redirect_back_or_to(root_path)
    end
  end

  private

  def after_inactive_sign_up_path_for(_)
    new_agent_session_path
  end

  def after_update_path_for(_)
    edit_agent_registration_path
  end
end
