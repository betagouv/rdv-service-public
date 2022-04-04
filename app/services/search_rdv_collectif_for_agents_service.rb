# frozen_string_literal: true

class SearchRdvCollectifForAgentsService < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def perform
    rdvs = Rdv.where(organisation: @form.organisation).collectif
      .where(motif: @form.motif).with_remaining_seats
      .where("starts_at > ?", @form.from_date)

    if @form.lieu_ids.present?
      rdvs = rdvs.where(lieu_id: @form.lieu_ids)
    end

    if @form.agent_ids.present?
      rdvs = rdvs.joins(:agents_rdvs).where(agents_rdvs: { agent_id: @form.agent_ids })
    end

    rdvs.distinct.order("starts_at asc")
  end
end
