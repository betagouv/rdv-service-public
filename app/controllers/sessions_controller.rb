class SessionsController < Devise::SessionsController
  after_action :sign_out_other_scope, only: :create

  private

  def sign_out_other_scope
    sign_out :agent if resource_name == User && return
    sign_out :user if resource_name == Agent && return
  end
end
