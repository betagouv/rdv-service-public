module SuperAdmins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def github
      email = request.env["omniauth.auth"]["info"]["email"]
      super_admin = SuperAdmin.find_by(email: email)

      if super_admin.present?
        sign_in super_admin
        redirect_to admin_pros_path
      else
        flash[:alert] = "Compte GitHub non autorisé"
        Rails.logger.error("OmniAuth failed for #{email}")
        redirect_to root_path
      end
    end

    def failure
      redirect_to root_path
    end
  end
end
