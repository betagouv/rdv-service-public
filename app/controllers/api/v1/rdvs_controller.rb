# frozen_string_literal: true

class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  def index
    rdvs = policy_scope(Rdv).where(params.permit(:organisation_id))
    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?
    render_collection(rdvs)
  end

  def update
    rdv = policy_scope(Rdv).find(params[:id])

    if rdv_params[:status].present?
      # Rdvs UX forces a manual change to unknown status before changing to another status
      # Since API has no UI for this, we do it automatically
      Admin::EditRdvForm.new(rdv, current_agent.roles.take).update(status: :unknown, ignore_benign_errors: true)
    end

    Admin::EditRdvForm.new(rdv, current_agent.roles.take).update(**rdv_params, ignore_benign_errors: true)

    render_record rdv
  end

  private

  def rdv_params
    params.require(:rdv).permit(:status)
  end
end
