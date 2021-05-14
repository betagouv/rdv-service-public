# frozen_string_literal: true

module SuperAdmins
  class UsersController < SuperAdmins::ApplicationController
    def sign_in_as
      user = User.find(params[:id])
      if sign_in_as_allowed?
        sign_out(:agent)
        sign_in(:user, user, bypass: true)
        redirect_to root_url
      else
        flash[:error] = "Fonctionnalité désactivée sur cet environnement."
        redirect_to super_admins_user_path(user)
      end
    end
  end
end
