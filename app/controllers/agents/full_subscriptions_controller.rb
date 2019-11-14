class Agents::FullSubscriptionsController < AgentAuthController
  layout 'registration'

  def new
    @subscription = Agent::FullSubscription.new(agent: current_agent, first_name: current_agent.first_name, last_name: current_agent.last_name, service_id: current_agent.service_id)
    authorize(@subscription)
  end

  def create
    build_subscription
    authorize(@subscription)
    if @subscription.save
      if current_agent.organisation
        redirect_to authenticated_agent_root_path(_conversion: 'agent-created'), notice: 'Merci de votre inscription'
      else
        redirect_to new_organisation_path(_conversion: 'agent-created')
      end
    else
      render 'new'
    end
  end

  private

  def build_subscription
    @subscription = Agent::FullSubscription.new(full_subscription_params)
    @subscription.agent = current_agent
  end

  def full_subscription_params
    params.require(:agent_full_subscription).permit(:first_name, :last_name, :service_id)
  end
end
