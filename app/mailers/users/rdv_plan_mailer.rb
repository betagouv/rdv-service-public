class Users::RdvPlanMailer < ApplicationMailer
  before_action { @rdv_plan = params[:rdv_plan] }

  def invitation
    mail(
      subject: "Vous êtes invité.e à prendre rendez-vous",
      to: @rdv_plan.user.email
    )
  end

  private

  def domain
    @rdv_plan.motif.organisation.domain
  end
end
