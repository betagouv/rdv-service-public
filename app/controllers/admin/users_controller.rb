module Admin
  class UsersController < Admin::ApplicationController
    def sign_in_as
      user = User.find(params[:id])
      if sign_in_as_allowed?
        sign_out(:agent)
        sign_in(:user, user, bypass: true)
        redirect_to root_url
      else
        flash[:error] = "Fonctionnalité désactivée sur cet environnement."
        redirect_to admin_user_path(user)
      end
    end
  end
end
