class SearchRdvCollectifForAgentsService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def next_availabilities
    lieux.map do |lieu|
      OpenStruct.new(lieu: lieu, next_availability: rdvs.where(lieu: lieu).first)
    end.sort_by do |result|
      result.next_availability.starts_at
    end
  end

  def slot_search
    OpenStruct.new(
      lieu: @form.organisation.lieux.find(@form.lieu_ids.first),
      creneaux: rdvs
    )
  end

  private

  def lieux
    @form.organisation.lieux.joins(:rdvs).merge(rdvs_scope).distinct
  end

  def rdvs_scope
    rdvs = Rdv.where(organisation: @form.organisation).collectif
      .where(motif: @form.motif).with_remaining_seats
      .where("starts_at > ?", @form.from_date)

    if @form.lieu_ids.present?
      rdvs = rdvs.where(lieu_id: @form.lieu_ids)
    end

    if @form.agent_ids.present?
      rdvs = rdvs.joins(:agents_rdvs).where(agents_rdvs: { agent_id: @form.agent_ids })
    end

    rdvs
  end

  def rdvs
    rdvs_scope.distinct.order("starts_at asc")
  end
end
