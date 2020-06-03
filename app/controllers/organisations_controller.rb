class OrganisationsController < ApplicationController
  layout 'welcome'

  def new
    @organisation = Organisation.new
    @organisation.agents << @organisation.agents.build
  end

  def create
    @organisation = Organisation.new(organisation_params)
    @organisation.agents.each do |agent|
      agent.role = :admin
      agent.skip_confirmation!
    end
    return render :new unless @organisation.save

    agent = @organisation.agents.first
    agent.deliver_invitation if agent.from_safe_domain?
  end

  def organisation_params
    params.require(:organisation).permit(:name, :departement, agents_attributes: [:email, :service_id])
  end
end
