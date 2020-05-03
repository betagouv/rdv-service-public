# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :set_paper_trail_whodunnit
    around_action :skip_bullet if defined?(Bullet)

    helper_method :sign_in_as_allowed?

    def user_for_paper_trail
      "[SuperAdmin] #{current_agent.email}"
    end

    def skip_bullet
      previous_value = Bullet.enable?
      Bullet.enable = false
      yield
    ensure
      Bullet.enable = previous_value
    end

    def sign_in_as_allowed?
      ENV.fetch('SIGN_IN_AS_ALLOWED') { false }
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
