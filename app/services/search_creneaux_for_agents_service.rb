class SearchCreneauxForAgentsService < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def perform
    OpenStruct.new(
      lieux: lieux,
      next_availability_by_lieux: next_availability_by_lieux,
      creneaux_by_lieux: creneaux_by_lieux
    )
  end

  private

  def lieux
    return [] unless @form.motif.present?

    return @lieux unless @lieux.nil?

    @lieux = @form.organisation.lieux
    @lieux = \
      if @form.lieu_ids.present?
        @lieux.where(id: @form.lieu_ids)
      else
        @lieux.for_motif(@form.motif)
      end
    @lieux = @lieux.where(id: PlageOuverture.where(agent_id: @form.agent_ids).pluck(:lieu_id)) if @form.agent_ids.any?
    @lieux.ordered_by_name
    @lieux
  end

  def creneaux_by_lieux
    @creneaux_by_lieux ||= lieux.each_with_object({}) do |lieu, creneaux_by_lieux|
      creneaux_by_lieux[lieu.id] = CreneauxBuilderService
        .perform_with(@form.motif.name, lieu, @form.date_range, for_agents: true, agent_ids: @form.agent_ids)
    end
  end

  def next_availability_by_lieux
    @next_availability_by_lieux = []
    lieux.each do |lieu|
      @next_availability_by_lieux[lieu.id] = FindAvailabilityService
        .perform_with(@form.motif.name, lieu, Date.today, for_agents: true)
    end
    @next_availability_by_lieux
  end
end
