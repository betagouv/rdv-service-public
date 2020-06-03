class Agents::OrganisationsController < AgentAuthController
  include OrganisationsHelper

  respond_to :html, :json

  before_action :set_organisation, except: :index

  def index
    @organisations = policy_scope(Organisation)
    if @organisations.count == 1
      redirect_to organisation_home_path(@organisations.first)
    else
      render layout: 'registration'
    end
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
    respond_right_bar_with @organisation, location: organisation_path(@organisation)
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name, :horaires, :phone_number)
  end
end
