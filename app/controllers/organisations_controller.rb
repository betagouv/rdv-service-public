class OrganisationsController < DashboardAuthController
  respond_to :html, :json

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
    respond_right_bar_with @organisation
  end

  def create
    @organisation = Organisation.new(organisation_params)
    authorize(@organisation)
    if @organisation.save
      current_pro.update_attribute :organisation_id, @organisation.id
      redirect_to authenticated_pro_root_path(_conversion: 'organisation-created'), notice: 'Merci de votre inscription'
    else
      render new_organisation_path, layout: "registration"
    end
  end

  def update
    authorize(@organisation)
    flash[:notice] = "Organisation mise à jour" if @organisation.update(organisation_params)
    respond_right_bar_with @organisation, location: organisation_path(@organisation)
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
