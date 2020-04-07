class Agents::RdvWizard::Step3Controller < Agents::RdvWizard::BaseController
  def new
    skip_authorization
    @rdv = Rdv.new(query_params)
    @rdv.organisation = current_organisation
  end

  def create
    @rdv = Rdv.new(rdv_params)
    @rdv.organisation = current_organisation
    authorize(@rdv)
    if @rdv.save
      redirect_to @rdv.agenda_path_for_agent(current_agent), notice: "Le rendez-vous a été créé."
    else
      render 'new'
    end
  end
end
