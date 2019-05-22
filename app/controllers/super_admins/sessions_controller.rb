module SuperAdmins
  class SessionsController < ApplicationController
    def destroy
      if super_admin_signed_in?
        sign_out :super_admin
      end

      redirect_to root_path
    end
  end
end
