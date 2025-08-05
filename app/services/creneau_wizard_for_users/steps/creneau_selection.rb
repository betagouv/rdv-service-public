class CreneauWizardForUsers::Steps::CreneauSelection
  def initialize(web_search_context)
    @context = web_search_context
  end

  def no_availability?
    creneaux.empty? && @context.next_availability.nil?
  end

  delegate :creneaux, to: :creneaux_search

  private

  def creneaux_search
    @context.creneaux_search
  end
end
