module SuperAdmins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def github
      email = request.env["omniauth.auth"]["info"]["email"]
      super_admin = SuperAdmin.find_by(email: email)

      if super_admin.present?
        sign_in super_admin
        redirect_to admin_agents_path
      else
        flash[:alert] = "Compte GitHub non autorisé"
        Rails.logger.error("OmniAuth failed for #{email}")
        redirect_to root_path
      end
    end

    def franceconnect
      puts(request.env["omniauth.auth"])
      puts(request.env["omniauth.auth"]['info'])
      puts(request.env["omniauth.auth"])
      flash[:alert] = "Compte GitHub non autorisé"
      email = request.env["omniauth.auth"]["info"]["email"]
      super_admin = SuperAdmin.find_by(email: email)

      if super_admin.present?
        sign_in super_admin
        redirect_to admin_agents_path
      else
        flash[:alert] = "Compte GitHub non autorisé"
        Rails.logger.error("OmniAuth failed for #{email}")
        redirect_to root_path
      end
    end

    def failure
      Rails.logger.error("Failure")
      redirect_to root_path
    end
  end
end
