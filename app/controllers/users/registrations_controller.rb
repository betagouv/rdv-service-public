class Users::RegistrationsController < Devise::RegistrationsController
  layout :user_devise_layout

  def destroy
    authorize([:user, resource])
    resource.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  private

  def user_devise_layout
    user_signed_in? ? 'application_user' : 'registration'
  end

  def after_inactive_sign_up_path_for(_)
    new_user_session_path
  end
end
