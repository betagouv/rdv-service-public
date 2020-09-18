class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    # copied from https://github.com/heartcombo/devise/blob/master/app/controllers/devise/confirmations_controller.rb
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource) do
        redirect_to after_confirmation_path_for(resource_name, resource)
      end
    else
      redirect_to new_user_session_path, flash: { error: resource.errors.full_messages.join(", ") }
    end
  end

  protected

  def after_confirmation_path_for(_resource_name, resource)
    token = resource.send(:set_reset_password_token)
    edit_password_path(resource, reset_password_token: token, from_confirmation: true)
  end
end
