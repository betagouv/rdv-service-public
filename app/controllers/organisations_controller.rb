class OrganisationsController < ApplicationController
  layout 'application'

  def new
    @organisation = Organisation.new
    @organisation.agents.build
  end

  def create
    @organisation = Organisation.new(organisation_params)
    @organisation.agents.each do |agent|
      agent.role = :admin
      # because we're not passing through the regular `.invite!` method, we
      # have to hack our way into creating a user that bypasses validations and
      # callbacks:
      agent.skip_confirmation!
      agent.skip_invitation = true
      agent.define_singleton_method(:password_required?) { false }
    end
    return render :new unless @organisation.save

    agent = @organisation.agents.first
    agent.deliver_invitation if agent.from_safe_domain?
  end

  def organisation_params
    params.require(:organisation).permit(:name, :departement, agents_attributes: [:email, :service_id])
  end
end
