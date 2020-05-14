class OrganisationsController < ApplicationController
  layout 'welcome'

  def new; end

  def create
    ActiveRecord::Base.transaction do
      agent = Agent.create(
        agent_params.merge(
          role: :admin,
          service: Service.find(service_params[:service])
        )
      )

      agent.invite! do |u|
        u.skip_invitation = !agent.from_safe_domain?
      end

      organisation = Organisation.create(
        organisation_params.merge(
          agents: [agent]
        )
      )
      organisation.save
    end
  end

  def agent_params
    params.require(:organisation).permit(:email)
  end

  def organisation_params
    params.require(:organisation).permit(:name, :departement)
  end

  def service_params
    params.require(:organisation).permit(:service)
  end
end
