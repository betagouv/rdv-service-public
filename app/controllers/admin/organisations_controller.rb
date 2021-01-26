class Admin::OrganisationsController < AgentAuthController
  include OrganisationsHelper

  respond_to :html, :json

  before_action :set_organisation, except: :index
  before_action :follow_unique, only: :index

  def index
    @organisations_by_departement = policy_scope(Organisation).order(:name).group_by(&:departement)
    render layout: "registration"
  end

  def show
    authorize(@organisation)
  end

  def edit
    authorize(@organisation)
    respond_right_bar_with @organisation
  end

  def update
    authorize(@organisation)
    flash[:notice] = "L'organisation a été modifiée." if @organisation.update(organisation_params)
    respond_right_bar_with @organisation, location: admin_organisation_path(@organisation)
  end

  def new
    @organisation = Organisation.new
    authorize(@organisation)
    render :new, layout: "registration"
  end

  def create
    @organisation = Organisation.new(new_organisation_params)
    authorize(@organisation)
    @organisation.agents = [current_agent]
    if @organisation.save
      redirect_to organisation_home_path(@organisation), flash: { success: "Organisation créée !" }
    else
      render :new, layout: "registration"
    end
  end

  private

  def current_organisation
    # overrides AgentAuthController's because here it's params[:id]
    if params[:id].present?
      current_agent.organisations.find(params[:id])
    else
      current_agent.organisations.first # necessary for pundit but should not
    end
  end

  def organisation_params
    params.require(:organisation).permit(:name, :horaires, :phone_number, :website, :email, :human_id)
  end

  def new_organisation_params
    params.require(:organisation).permit(:name, :departement)
  end

  def follow_unique
    return if params[:follow_unique].blank? || policy_scope(Organisation).count != 1

    redirect_to organisation_home_path(policy_scope(Organisation).first)
  end
end
