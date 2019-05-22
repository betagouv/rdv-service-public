module Pros
  class RegistrationsController < Devise::RegistrationsController
    private

    def after_inactive_sign_up_path_for(_)
      new_pro_session_path
    end
  end
end
