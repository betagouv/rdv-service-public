class Users::SessionsController < Devise::SessionsController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  before_action :exclude_signed_in_agents, only: [:new]
  after_action :allow_iframe

  def create
    if auth_options[:scope] == :user && (self.resource = Agent.find_by(email: params[:user]["email"])) && resource.valid_password?(params[:user]["password"])
      set_flash_message!(:notice, :signed_in)
      sign_in(:agent, resource)

      checker = PasswordChecker.new(params[:user][:password]) # voir aussi app/controllers/agents/sessions_controller.rb
      if checker.too_weak?
        flash[:notice] = nil
        flash[:alert] = checker.error_message(current_domain.name)
      end

      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  def destroy
    @connected_with_franceconnect = user_signed_in? && session[:connected_with_franceconnect]
    # so it's accessible in after_sign_out_path_for
    super
  end

  private

  def exclude_signed_in_agents
    return true unless agent_signed_in?

    redirect_to(
      root_path,
      flash: { error: "Déconnectez-vous d'abord de votre compte agent pour vous connecter en tant qu'utilisateur" }
    )
  end

  # Copied from devise-4.8.1/app/controllers/devise/sessions_controller.rb
  # We needed to override the call to redirect_to to set `allow_other_host: true`.
  def respond_to_on_destroy
    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name), allow_other_host: true }
    end
  end
end
