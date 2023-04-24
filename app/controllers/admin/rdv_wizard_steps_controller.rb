# frozen_string_literal: true

class Admin::RdvWizardStepsController < AgentAuthController
  include RdvsHelper

  before_action :set_agent

  PERMITTED_PARAMS = [
    :motif_id, :duration_in_min, :starts_at, :lieu_id, :context, :service_id,
    :organisation_id, :ignore_benign_errors,
    { agent_ids: [], user_ids: [], rdvs_users_attributes: {}, lieu_attributes: Rdv::ACCEPTED_NESTED_LIEU_ATTRIBUTES },
  ].freeze

  def new
    @rdv_wizard = rdv_wizard_for(query_params)

    @rdv = @rdv_wizard.rdv
    set_services_and_motifs if current_step == "step1"
    authorize(@rdv_wizard.rdv, :new?)
    render current_step
  end

  def create
    @rdv_wizard = rdv_wizard_for(rdv_params)
    @rdv = @rdv_wizard.rdv
    set_services_and_motifs if current_step == "step1"
    authorize(@rdv_wizard.rdv, :create?)

    if @rdv.lieu&.new_record?
      # We’re creating a new Lieu along the new Rdv. That means this is a single-use Lieu.
      # Otherwise (if the lieu isn't a new record being created), it's a regular, enabled Lieu.
      @rdv.lieu.organisation = @rdv.organisation
      @rdv.lieu.availability = :single_use
    end

    if @rdv_wizard.save
      redirect_to @rdv_wizard.success_path, @rdv_wizard.success_flash
    else
      render current_step
    end
  end

  protected

  def set_agent
    @agent = params[:agent_ids].present? ? Agent.find(params[:agent_ids].first) : current_agent
  end

  def current_step
    return Admin::RdvWizardForm::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise "Invalid step: #{step.inspect}" unless step.in?(Admin::RdvWizardForm::STEPS)

    step
  end

  def rdv_wizard_for(request_params)
    wizard_class = {
      step1: Admin::RdvWizardForm::Step1,
      step2: Admin::RdvWizardForm::Step2,
      step3: Admin::RdvWizardForm::Step3,
      step4: Admin::RdvWizardForm::Step4,
    }.fetch(current_step.to_sym)

    wizard_class.new(current_agent, current_organisation, request_params)
  end

  def set_services_and_motifs
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, @agent)
    @services = policy_scope(Service).where(id: @motifs.pluck(:service_id).uniq)
    @rdv_wizard.service_id = @services.first.id if @services.count == 1
  end

  def rdv_params
    rdv_params = params.require(:rdv).permit(PERMITTED_PARAMS)
    if rdv_params[:lieu_id].present?
      # Prevent editing an existing enabled lieu, if both lieu_id and lieu_attributes are passed.
      # This is not supposed to happen in the frontend,
      #   cf rdv_lieu.js: the irrelevant fields are disabled.
      rdv_params.delete(:lieu_attributes)
    end
    rdv_params
  end

  def query_params
    params.permit(PERMITTED_PARAMS)
  end
end
