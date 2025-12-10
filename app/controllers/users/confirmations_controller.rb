class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    # copied from https://github.com/heartcombo/devise/blob/master/app/controllers/devise/confirmations_controller.rb
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)

      sign_in(:user, resource)
      respond_with_navigational(resource) do
        redirect_to after_sign_in_path_for(resource_name)
      end
    else
      redirect_to new_user_session_path, flash: { error: resource.errors.full_messages.join(", ") }
    end
  end
end
