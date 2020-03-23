class SessionsController < Devise::SessionsController
  after_action :sign_out_other_scope, only: :create

  def create
    if auth_options[:scope] == :user && (self.resource = Agent.find_by(email: params[:user]["email"]))
      set_flash_message!(:notice, :signed_in)
      sign_in(:agent, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  private

  def sign_out_other_scope
    sign_out :agent if resource_name == User && return
    sign_out :user if resource_name == Agent && return
  end
end
