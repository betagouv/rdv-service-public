# All Administrate controllers inherit from this `SuperAdmins::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module SuperAdmins
  class ApplicationController < Administrate::ApplicationController
    include DomainDetection
    include Administrate::Punditize
    rescue_from Pundit::NotAuthorizedError, with: :super_admin_not_authorized

    helper all_helpers_from_path "app/helpers"

    if ENV["ADMIN_BASIC_AUTH_PASSWORD"].present?
      # don't set this env var in prod!
      http_basic_authenticate_with name: "rdv-solidarites", password: ENV["ADMIN_BASIC_AUTH_PASSWORD"]
    else
      before_action :authenticate_super_admin!
    end
    before_action :set_paper_trail_whodunnit
    before_action :set_sentry_context
    after_action :verify_authorized

    helper_method :sign_in_as_allowed?

    # Pundit configuration for Administrate
    def policy_namespace
      [:super_admin]
    end

    def pundit_user
      current_super_admin
    end
    # End Pundit configuration for Administrate

    private

    def super_admin_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore
      flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
      redirect_to(request.referer || super_admins_root_path)
    end

    def user_for_paper_trail
      current_super_admin.name_for_paper_trail
    end

    def authenticate_super_admin!
      return redirect_to connexion_super_admins_path unless super_admin_signed_in?

      super
    end

    def sign_in_as_allowed?
      ENV.fetch("SIGN_IN_AS_ALLOWED", false)
    end

    def set_sentry_context
      Sentry.set_user({ email: current_super_admin.email }) if super_admin_signed_in?
    end

    def current_super_admin
      if ENV["ADMIN_BASIC_AUTH_PASSWORD"].present?
        return SuperAdmin.new(first_name: "Local", last_name: "SuperAdmin", role: :legacy_admin)
      end

      super
    end
  end
end
