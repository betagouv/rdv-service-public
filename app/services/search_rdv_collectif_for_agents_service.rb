# frozen_string_literal: true

class SearchRdvCollectifForAgentsService < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def perform
    Rdv.where(organisation: @form.organisation).collectif
      .where(motif: @form.motif).with_remaining_seats
      .where("starts_at > ?", @form.from_date)
      .order("starts_at asc")
  end
end
