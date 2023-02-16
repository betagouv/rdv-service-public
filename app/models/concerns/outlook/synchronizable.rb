# frozen_string_literal: true

module Outlook
  module Synchronizable
    extend ActiveSupport::Concern

    included do
      attr_accessor :skip_outlook_update

      after_commit :sync_create_in_outlook_asynchronously, on: :create

      after_commit :sync_update_in_outlook_asynchronously, on: :update, unless: :skip_outlook_update

      after_destroy :sync_destroy_in_outlook_asynchronously

      alias_attribute :exists_in_outlook?, :outlook_id?

      scope :exists_in_outlook, -> { where.not(outlook_id: nil) }

      delegate :connected_to_outlook?, to: :agent, prefix: true
    end

    def sync_create_in_outlook_asynchronously
      return unless agent_connected_to_outlook? && !exists_in_outlook? && !outlook_create_in_progress?

      update(outlook_create_in_progress: true)
      Outlook::CreateEventJob.perform_later(self)
    end

    def sync_update_in_outlook_asynchronously
      if cancelled? || soft_deleted?
        sync_destroy_in_outlook_asynchronously
      elsif exists_in_outlook?
        Outlook::UpdateEventJob.perform_later(self) if agent_connected_to_outlook?
      else
        sync_create_in_outlook_asynchronously
      end
    end

    def sync_destroy_in_outlook_asynchronously
      return unless agent_connected_to_outlook? && exists_in_outlook?

      Outlook::DestroyEventJob.perform_later(outlook_id, agent)
    end
  end
end
