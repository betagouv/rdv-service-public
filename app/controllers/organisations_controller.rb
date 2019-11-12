class OrganisationsController < DashboardAuthController
  respond_to :html, :json

  before_action :redirect_if_agent_incomplete, only: :index

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
    @date = params[:date] ? Date.parse(params[:date]) : nil
    authorize(@organisation)
  end

  private

  def redirect_if_agent_incomplete
    return unless agent_signed_in?

    redirect_to(new_agents_full_subscription_path) && return unless current_agent.complete?
  end
end
