class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end

  def new
  end

  def redirect
    user = User.where(caisse_affiliation: 1).find_by(affiliation_number: params[:affiliation_number])
    if user.raw_invitation_token == params[:invitation_token]
      redirect_to accept_user_invitation_url(invitation_token: user.raw_invitation_token)
    else
      flash { error: "Les informations renseignées ne correspondent pas à un compte existant."}
    end
  end
end
