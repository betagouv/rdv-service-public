class Users::PasswordsController < Devise::PasswordsController
  def new
    self.resource = resource_class.new(params.permit(:email))
  end
end
