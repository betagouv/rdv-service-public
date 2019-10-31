class OrganisationsController < DashboardAuthController
  respond_to :html, :json

  def index
    @organisations = policy_scope(Organisation)
    if @organisations.count == 1
      redirect_to organisation_path(@organisations.first)
    else
      render layout: 'registration'
    end
  end

  def show
    @organisation = current_organisation
    authorize(@organisation)
  end
end
