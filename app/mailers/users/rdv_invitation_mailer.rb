class Users::RdvInvitationMailer < ApplicationMailer
  before_action { @rdv_invitation = params[:rdv_invitation] }

  def invitation
    mail(
      subject: "Vous êtes invité.e à prendre rendez-vous",
      to: @rdv_invitation.user.user_to_notify.email
    )
  end

  private

  def domain
    @rdv_invitation.organisation.domain
  end
end
