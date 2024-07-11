class AdminChangesAgentServices
  include ActiveModel::Model

  def initialize(agent, new_service_ids)
    @agent = agent
    @old_services = agent.services.to_a
    @new_services = Service.where(id: new_service_ids)
  end

  # validate :at_least_one_service
  validate :removed_services_dont_have_plages

  private

  def at_least_one_service
    if @new_services.empty?
      errors.add(:service_ids, "Un agent doit avoir au moins un service")
    end
  end

  def removed_services_dont_have_plages
    removed_services.each do |removed_service|
      if @agent.plage_ouvertures.any? { |plage| plage.motifs.any? { |motif| motif.service == removed_service } }
        errors.add(:service_ids, "Le retrait du service n'a pu aboutir car l'agent a toujours des plages d'ouverture actives sur le service : #{removed_service.short_name}")
      end
    end
  end

  def removed_services
    @old_services.to_set.difference(@new_services.to_set)
  end
end
