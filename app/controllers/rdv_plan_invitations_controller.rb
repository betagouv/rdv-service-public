class RdvPlanInvitationsController < ApplicationController
  layout "application_base"

  def show
    @rdv_plan = RdvPlan.find_by(invitation_token: params[:rdv_plan_invitation_token])
  end
end
