class RedirectController < ApplicationController
  def short_rdv_without_id
    @participation = Participation.find_by!(restricted_auth_token: params[:tkn])

    redirect_to users_rdv_path(@participation.rdv, invitation_token: params[:tkn])
  end
end
