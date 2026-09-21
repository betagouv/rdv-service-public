class Agents::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_action { @active_agent_preferences_menu_item = :compte }

  def pundit_user
    AgentContext.new(current_agent)
  end

  def destroy
    removal_services = current_agent.organisations.map { AgentRemoval.new(@agent, _1) }
    if removal_services.all?(&:valid?)
      deleted_agent_email = current_agent.email
      removal_services.each(&:remove!)

      # `Devise.sign_out_all_scopes` (activé par défaut) fait qu'un `sign_out` sans scope déconnecte
      # tous les scopes Warden et vide déjà la session entière — si un super admin usurpe cet agent,
      # cela le déconnecterait aussi. On ne déconnecte donc que le scope `:agent` dans ce cas (comme
      # `Agents::SessionsController#destroy`), sans toucher au reste de la session.
      sign_out(resource_name)

      if session[:super_admin_signed_in_as_agent]
        session.delete(:super_admin_signed_in_as_agent)
        flash[:notice] = "Le compte de #{deleted_agent_email} a été supprimé."
        redirect_to super_admins_agents_path
      else
        reset_session

        flash[:notice] = I18n.t("devise.failure.deleted_account")
        redirect_to root_path
      end
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
