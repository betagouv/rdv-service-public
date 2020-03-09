class Users::RegistrationsController < Devise::RegistrationsController
  layout :user_devise_layout

  def create
    prepare_resource

    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      set_minimum_password_length
      respond_with resource
    end
  end

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

  def prepare_resource
    resource = User.find_by(email: sign_up_params[:email], confirmed_at: nil)
    user = build_resource(sign_up_params)
    
    if resource.present? && resource.encrypted_password.blank? && user.valid_except_email?
      # email exist but has never signin
      resource.password = sign_up_params[:password]
      resource.save(validate: false)
      resource.sign_up_params = sign_up_params.except(:password)
      resource.send(:generate_confirmation_token)
      Devise::Mailer.confirmation_instructions(resource, resource.instance_variable_get(:@raw_confirmation_token), sign_up_params: sign_up_params).deliver_now
    elsif resource.nil? || resource.encrypted_password.blank?
      # email dont exist or email has never signin => error in login
      resource = user
      resource.save
      resource.errors.delete(:email) if resource.present?
    end
    self.resource = resource
  end

end
