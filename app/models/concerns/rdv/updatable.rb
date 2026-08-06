module Rdv::Updatable
  extend ActiveSupport::Concern

  def update_and_notify(author, attributes, &block)
    Rdv.transaction do
      @old_agent_ids = agent_ids.to_a
      assign_attributes(attributes) # this can assign agent_ids and thus persist

      previous_participations = participations.select(&:persisted?)
      remove_duplicate_participations
      set_created_by_for_new_participations(author)

      if block_given?
        unless block.call(self) # yield RDV before saving, can be used to run policy check
          raise ActiveRecord::Rollback
        end
      end

      if save
        notify!(author, previous_participations)
        true
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def remove_duplicate_participations
    existing_participations = Participation.where(rdv_id: id).to_a # pour éviter une requête N+1

    participations.each do |participation|
      existing_participation = existing_participations.find { |p| p.user_id == participation.user_id }
      next unless existing_participation

      participation.id = existing_participation.id
    end.uniq!
  end

  def set_created_by_for_new_participations(author) # rubocop:disable Naming/AccessorMethodName
    participations.select(&:new_record?).each { |participation| participation.created_by = author }
  end

  def notify!(author, previous_participations)
    if rdv_updated?
      Notifiers::RdvUpdated.new(self, author, old_agent_ids: @old_agent_ids).perform
    end

    if collectif? && previous_participations.sort != participations.sort
      Notifiers::RdvCollectifParticipations.perform_with(self, author, previous_participations)
    end
  end

  def rdv_updated?
    starts_at_changed? || lieu_changed? || visio_url_custom_changed?
    # || agents_changed? désactivé pour l’instant cf https://github.com/betagouv/rdv-service-public/pull/5399
  end

  def lieu_changed?
    # Rappel :
    # - si le motif du RDV est de type `public_office`, le lieu est forcément renseigné, sinon il est forcément nil
    # - il est impossible de changer le motif d'un RDV
    return false unless lieu

    previous_changes["lieu_id"].present? || lieu.previous_changes.keys.include?("name") || lieu.previous_changes.keys.include?("address")
  end

  def starts_at_changed?
    previous_changes["starts_at"].present?
  end

  def visio_url_custom_changed?
    collectif? && visio? && previous_changes["visio_url_custom"].present?
  end

  def agents_changed?
    # we cannot use ActiveModel::Dirty methods here for this has_many association
    @old_agent_ids.to_set != agent_ids.to_set
  end
end
