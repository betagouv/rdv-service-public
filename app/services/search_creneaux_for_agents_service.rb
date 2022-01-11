# frozen_string_literal: true

class SearchCreneauxForAgentsService < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def perform
    lieux.map { build_result(_1) }.compact # NOTE: LOOP 1 over lieux.
  end

  private

  def build_result(lieu)
    # utiliser les ids des agents pour ne pas faire de requêtes supplémentaire
    next_availability = NextAvailabilityService.find(@form.motif, lieu, @form.date_range.begin, @form.agent_ids)
    creneaux = SlotBuilder.available_slots(@form.motif, lieu, @form.date_range, OffDays.all_in_date_range(@form.date_range), @form.agent_ids)
    return nil if creneaux.empty? && next_availability.nil?

    OpenStruct.new(lieu: lieu, next_availability: next_availability, creneaux: creneaux)
  end

  def lieux
    return [] if @form.motif.blank?

    return @lieux unless @lieux.nil?

    @lieux = @form.organisation.lieux
    @lieux = \
      if @form.lieu_ids.present?
        @lieux.where(id: @form.lieu_ids)
      else
        @lieux.for_motif(@form.motif)
      end

    @lieux = @lieux.where(id: PlageOuverture.where(agent_id: @form.agent_ids).select(:lieu_id)) if @form.agent_ids.present?
    @lieux = @lieux.ordered_by_name
    @lieux
  end
end
