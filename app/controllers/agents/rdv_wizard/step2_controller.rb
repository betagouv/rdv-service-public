class Agents::RdvWizard::Step2Controller < Agents::RdvWizard::BaseController
  def new
    skip_authorization
    rdv = Rdv.new(query_params)
    rdv.agents << current_agent unless query_params[:agent_ids].present?
    @agents_authorize = rdv.motif.service.agents.complete.active.joins(:organisations).where(organisations: { id: current_organisation.id })
    @agents_authorize += current_organisation.agents.complete.active.includes(:service).secretariat if rdv.motif.for_secretariat
    @rdv_wizard = RdvWizard.new(rdv.to_step_params.merge(current_step: 2))
    @rdv_wizard.starts_at ||= Time.zone.now
    @rdv_wizard.duration_in_min ||= @rdv_wizard.motif.default_duration_in_min
    @rdv_wizard.organisation_id = current_organisation.id
  end

  def create
    rdv = Rdv.new(rdv_params)
    @rdv_wizard = RdvWizard.new(rdv.to_step_params.merge(current_step: 2))
    @rdv_wizard.organisation_id = current_organisation.id
    skip_authorization
    if @rdv_wizard.valid?
      redirect_to new_organisation_rdv_wizard_step3_path(@rdv_wizard.to_query)
    else
      render 'new'
    end
  end
end
