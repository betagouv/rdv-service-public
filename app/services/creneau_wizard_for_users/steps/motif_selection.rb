class CreneauWizardForUsers::Steps::MotifSelection
  def initialize(search_context)
    @context = search_context
  end

  def service_selected?
    services.count == 1
  end

  def services
    @services ||= @context.matching_motifs.includes(:service).map(&:service).uniq.sort_by do |service|
      service ? I18n.transliterate(service.name.downcase) : "Autres"
    end
  end

  def follow_up_motifs?
    @follow_up_motifs ||= Motif.where(service: services).where.not(bookable_by: :agents).exists?(follow_up: true, deleted_at: nil)
  end

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= @context.matching_motifs.uniq(&:name_with_location_type)
  end

  def motifs_grouped_by_service_id
    @motifs_grouped_by_service_id ||= @context.matching_motifs.group_by(&:service_id)
  end
end
