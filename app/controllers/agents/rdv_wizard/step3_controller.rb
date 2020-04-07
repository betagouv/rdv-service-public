class Agents::RdvWizard::Step3Controller < Agents::RdvWizard::BaseController
  def new
    skip_authorization
    @rdv = Rdv.new(query_params)
    @rdv.organisation = current_organisation
  end
end
