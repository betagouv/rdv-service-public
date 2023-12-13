module SuperAdmins
  class SessionsController < ApplicationController
    def destroy
      sign_out_all_scopes if super_admin_signed_in?

      redirect_to root_path
    end
  end
end
