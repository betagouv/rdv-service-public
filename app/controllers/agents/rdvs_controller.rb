class Agents::RdvsController < AgentAuthController
  before_action :set_rdv, only: %i[show visio]

  def show
    redirect_to admin_organisation_rdv_path(@rdv.organisation, @rdv)
  end

  def visio
    if @rdv.visio_url.present?
      redirect_to @rdv.visio_url, allow_other_host: true
    else
      flash[:error] = "Ce RDV n'a pas de visioconférence associée"
      redirect_to admin_organisation_rdv_path(@rdv.organisation, @rdv)
    end
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).find(params[:id])
    authorize(@rdv, policy_class: Agent::RdvPolicy)
  end

  def pundit_user
    current_agent
  end
end
