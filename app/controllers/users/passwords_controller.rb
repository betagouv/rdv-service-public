class Users::PasswordsController < Devise::PasswordsController
  layout "user_registration"

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
      return
    end

    super
  end

  def edit
    super
    @from_confirmation = params[:from_confirmation].present?
  end
end
