# frozen_string_literal: true

# All Administrate controllers inherit from this `SuperAdmins::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module SuperAdmins
  class ApplicationController < Administrate::ApplicationController
    helper all_helpers_from_path "app/helpers"

    if ENV["ADMIN_BASIC_AUTH_PASSWORD"].present?
      # don't set this env var in prod!
      http_basic_authenticate_with name: "rdv-solidarites", password: ENV["ADMIN_BASIC_AUTH_PASSWORD"]
    else
      before_action :authenticate_super_admin!
    end
    before_action :set_paper_trail_whodunnit
    around_action :skip_bullet if defined?(Bullet)

    helper_method :sign_in_as_allowed?

    def user_for_paper_trail
      return "SuperAdmin" if current_super_admin.nil?

      "[SuperAdmin] #{current_super_admin.email}"
    end

    def authenticate_super_admin!
      return redirect_to super_admin_github_omniauth_authorize_path unless super_admin_signed_in?

      super
    end

    def skip_bullet
      previous_value = Bullet.enable?
      Bullet.enable = false
      yield
    ensure
      Bullet.enable = previous_value
    end

    def sign_in_as_allowed?
      ENV.fetch("SIGN_IN_AS_ALLOWED", false)
    end
  end
end
