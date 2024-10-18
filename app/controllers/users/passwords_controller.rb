class Users::PasswordsController < Devise::PasswordsController
  layout "application_narrow"

  def new
    self.resource = resource_class.new(params.permit(:email))
  end

  def create
    user = User.find_by(email: resource_params[:email])
    if user && !user&.confirmed?
      self.resource = resource_class.send_confirmation_instructions(resource_params)
      if successfully_sent?(resource)
        respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
      else
        respond_with(resource)
      end
    elsif Agent.find_by(email: resource_params[:email])
      create_for_agent
    else
      super
    end
  end

  # This code is extracted from Devise::PasswordsController#create
  # with references to resource_class and resource_name hardcoded to Agent and :agent.
  def create_for_agent
    self.resource = Agent.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(:agent))
    else
      respond_with(resource)
    end
  end

  def edit
    super
    @from_confirmation = params[:from_confirmation].present?
  end
end
