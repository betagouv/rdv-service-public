class Agents::RdvWizard::Step1Controller < Agents::RdvWizard::BaseController
  def new
    rdv = Rdv.new(query_params)
    @agent = params[:agent_ids].present? ? Agent.find(params[:agent_ids].first) : current_agent
    @rdv_wizard = RdvWizard::Step1.new(rdv.to_step_params)
    @rdv_wizard.organisation_id = current_organisation.id
    skip_authorization
  end

  def create
    rdv = Rdv.new(rdv_params)
    @rdv_wizard = RdvWizard::Step1.new(rdv.to_step_params)
    @rdv_wizard.organisation_id = current_organisation.id
    skip_authorization
    if @rdv_wizard.valid?
      redirect_to new_organisation_rdv_wizard_step2_path(@rdv_wizard.to_query)
    else
      render 'new'
    end
  end
end
