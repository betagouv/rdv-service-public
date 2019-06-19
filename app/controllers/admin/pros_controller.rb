module Admin
  class ProsController < Admin::ApplicationController
    def sign_in_as
      pro = Pro.find(params[:id])
      sign_in(:pro, pro, { bypass: true })
      redirect_to root_url
    end
  end
end
