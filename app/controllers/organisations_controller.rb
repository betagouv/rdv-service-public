class OrganisationsController < ApplicationController
  layout 'application'

  def new
    @organisation = Organisation.new
    @organisation.agents.build
  end

  def create
    @agent = Agent.find_by(agent_email)
    if @agent
      unless @agent.admin?
        flash[:alert] = "Vous devez avoir les droits d'administration pour créer une nouvelle organisation."
        @organisation = Organisation.new(organisation_params)
        return render :new
      end

      @organisation = Organisation.new(basic_organisation_params)
      @organisation.agents << @agent

      return render :new unless @organisation.save

      return redirect_to new_agent_session_path, notice: "La nouvelle organisation #{@organisation.name} a été créée."
    end

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

  def basic_organisation_params
    params.require(:organisation).permit(:name, :departement)
  end

  def agent_email
    params.require(:organisation).require(:agents_attributes).permit(:email)
  end
end
