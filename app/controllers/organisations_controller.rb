class OrganisationsController < DashboardAuthController
  before_action :set_organisation, except: [:new, :create]

  def show
    authorize(@organisation)
  end

  def new
    @organisation = Organisation.new
    authorize(@organisation)
    render layout: "registration"
  end

  def edit
    authorize(@organisation)
  end

  def create
    @organisation = Organisation.new(organisation_params)
    authorize(@organisation)
    # redirect_to authenticated_root_path and return if current_pro.organisation
    if @organisation.save
      current_pro.update_attribute :organisation_id, @organisation.id
      redirect_to authenticated_root_path(_conversion: 'organisation-created'), notice: 'Merci de votre inscription'
    else
      render new_organisation_path, layout: "registration"
    end
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
