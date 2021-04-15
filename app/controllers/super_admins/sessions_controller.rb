module SuperAdmins
  class SessionsController < ApplicationController
    def destroy
      sign_out :super_admin if super_admin_signed_in?

      redirect_to root_path
    end
  end
end
