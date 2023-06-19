# frozen_string_literal: true

module Ants
  module EventSerializerAndListener
    extend ActiveSupport::Concern
    include Rails.application.routes.url_helpers

    included do
      attr_accessor :needs_sync_to_ants

      Rdv.before_commit do |rdv|
        Ants::EventSerializerAndListener.mark_for_sync([rdv])
      end
      User.before_commit do |user|
        if user.saved_change_to_ants_pre_demande_number?
          Ants::EventSerializerAndListener.mark_for_sync(user.rdvs)
        end
      end

      Rdv.after_commit do |rdv|
        Ants::EventSerializerAndListener.enqueue_sync_for_marked_record([rdv])
      end
      User.after_commit do |user|
        if user.saved_change_to_ants_pre_demande_number?
          Ants::EventSerializerAndListener.enqueue_sync_for_marked_record(user.rdvs)
        end
      end
    end

    def serialize_for_ants_api
      {
        meeting_point: lieu.name,
        appointment_date: starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        management_url: rdvs_short_url(self, host: organisation.domain.host_name),
      }
    end

    def self.mark_for_sync(rdvs)
      rdvs.each do |rdv|
        next unless rdv.in_the_future? && rdv.organisation.rdv_mairie?

        rdv.assign_attributes(needs_sync_to_ants: true)
      end
    end

    def self.enqueue_sync_for_marked_record(rdvs)
      rdvs.each do |rdv|
        next unless rdv.needs_sync_to_ants

        Ants::SyncEventJob.perform_later_for(rdv)
        rdv.assign_attributes(needs_sync_to_ants: false)
      end
    end
  end
end
