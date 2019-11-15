module Admin
  class UsersController < Admin::ApplicationController
    def sign_in_as
      sign_out(:agent)
      user = User.find(params[:id])
      sign_in(:user, user, bypass: true)
      redirect_to root_url
    end
  end
end
