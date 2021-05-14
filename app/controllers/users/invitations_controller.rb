class Users::InvitationsController < Devise::InvitationsController
  skip_before_action :authenticate_inviter!, only: [:new, :redirect]
  layout "user_registration"

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end

  def new ; end

  def redirect
    user = User.where(caisse_affiliation: "caf").find_by(affiliation_number: params[:invite][:affiliation_number])
    if user.simple_invitation_token == params[:invite][:simple_invitation_token]
      user.invite! { |u| u.skip_invitation = true }
      redirect_to accept_user_invitation_url(invitation_token: user.raw_invitation_token)
    else
      redirect_to :invitations_landing, flash: { error: "Les informations renseignées ne correspondent pas à un compte existant." }
    end
  end
end
