class SpecialitesController < DashboardAuthController
  before_action :set_organisation
  before_action :set_specialite, only: [:show, :edit, :update, :destroy]

  def index
    @specialites = policy_scope(Specialite).includes(:organisation)
    authorize(@specialites)
  end

  def show
    authorize(@specialite)
  end

  def new
    @specialite = Specialite.new(organisation: @organisation)
    authorize(@specialite)
  end

  def edit
    authorize(@specialite)
  end

  def create
    @specialite = Specialite.new(organisation: @organisation)
    @specialite.assign_attributes(specialite_params)
    authorize(@specialite)

    if @specialite.save
      redirect_to organisation_specialite_path(@organisation, @specialite), notice: 'Spécialité ajoutée.'
    else
      render :new
    end
  end

  def update
    authorize(@specialite)
    if @specialite.update(specialite_params)
      redirect_to organisation_specialite_path(@organisation, @specialite), notice: 'La spécialité a été modifiée.'
    else
      render :edit
    end
  end

  def destroy
    authorize(@specialite)
    @specialite.destroy
    redirect_to organisation_specialites_path(@organisation), notice: 'La spécialité a été supprimée.'
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def set_specialite
    @specialite = Specialite.find(params[:id])
  end

  def specialite_params
    params.require(:specialite).permit(:name)
  end
end
