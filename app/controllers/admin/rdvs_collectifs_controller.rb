# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  respond_to :html

  def index
    @rdvs = policy_scope(Rdv).joins(:motif).where(motifs: { collectif: true }).where(organisation: current_organisation)
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])
  end

  def new
    current_step = Admin::RdvWizardForm::STEPS.first

    klass = "Admin::RdvWizardForm::#{current_step.camelize}".constantize
    @rdv_wizard = klass.new(current_agent, current_organisation, {})
    @rdv = @rdv_wizard.rdv

    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).where(collectif: true)
    @services = policy_scope(Service).where(id: @motifs.pluck(:service_id).uniq)
    @rdv_wizard.service_id = @services.first.id if @services.count == 1

    authorize(@rdv_wizard.rdv, :new?)
  end
end
