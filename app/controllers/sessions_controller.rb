class SessionsController < Devise::SessionsController
  after_filter :sign_out_other_scope

  private
  def sign_out_other_scope
    sign_out :agent if resource_name == User && return
    sign_out :user if resource_name == Agent && return
  end

end