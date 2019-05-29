class OrganisationsController < DashboardAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
  end

  def edit
    authorize(@organisation)
  end

  def update
    authorize(@organisation)
    if @organisation.update(organisation_params)
      flash.notice = "Organisation mise à jour"
      redirect_to organisation_path(@organisation)
    else
      render :edit
    end
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
