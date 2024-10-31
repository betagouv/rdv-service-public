class Admin::ParticipationsController < AgentAuthController
  # Participation is @rdv.participations
  include ParticipationsHelper
  respond_to :js

  before_action :set_rdv
  before_action :set_participation

  def update
    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)
    if @participation.change_status_and_notify(current_agent, participation_params[:status])
      flash.now[:notice] = "Status de participation pour #{@participation.user.full_name} mis à jour"
    else
      flash.now[:error] = @participation.errors.full_messages.to_sentence
    end
    render "admin/rdvs/update"
  end

  def destroy
    authorize(@rdv, policy_class: Agent::RdvPolicy)
    if @rdv.participations.destroy(@participation)
      flash[:notice] = "La participation de l'usager au rdv a été supprimée."
    else
      flash[:error] = @participation.errors.full_messages.to_sentence
    end
    redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).find(params[:rdv_id])
  end

  def set_participation
    @participation = @rdv.participations.find(params[:id])
  end

  def participation_params
    params.require(:participation).permit(:status)
  end
end
