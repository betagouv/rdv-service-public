# frozen_string_literal: true

module Ants
  module AppointmentSerializerAndListener
    extend ActiveSupport::Concern

    ATTRIBUTES_TO_WATCH = %w[id status starts_at lieu_id].freeze

    included do
      attr_accessor :needs_sync_to_ants, :obsolete_application_id

      Rdv.before_commit do |rdv|
        Ants::AppointmentSerializerAndListener.mark_for_sync([rdv]) if rdv.watching_attributes_for_ants_api_changed?
      end
      User.before_commit do |user|
        Ants::AppointmentSerializerAndListener.mark_for_sync(user.rdvs) if user.saved_change_to_ants_pre_demande_number?
      end
      RdvsUser.before_commit do |rdv_user|
        Ants::AppointmentSerializerAndListener.mark_for_sync([rdv_user.rdv], obsolete_application_id: rdv_user.user.ants_pre_demande_number)
      end
      Lieu.before_commit do |lieu|
        Ants::AppointmentSerializerAndListener.mark_for_sync(lieu.rdvs) if lieu.saved_change_to_name?
      end

      Rdv.after_commit do |rdv|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record([rdv]) if rdv.watching_attributes_for_ants_api_changed?
      end
      User.after_commit do |user|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record(user.rdvs) if user.saved_change_to_ants_pre_demande_number?
      end
      RdvsUser.after_commit do |rdv_user|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record([rdv_user.rdv])
      end
      Lieu.after_commit do |lieu|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record(lieu.rdvs) if lieu.saved_change_to_name?
      end
    end

    def serialize_for_ants_api
      {
        meeting_point: lieu.name,
        appointment_date: starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        management_url: Rails.application.routes.url_helpers.rdvs_short_url(self, host: organisation.domain.host_name),
      }
    end

    def watching_attributes_for_ants_api_changed?
      saved_changes.keys & ATTRIBUTES_TO_WATCH
    end

    def self.mark_for_sync(rdvs, obsolete_application_id: nil)
      rdvs.each do |rdv|
        next unless rdv.in_the_future? && rdv.organisation.rdv_mairie?

        rdv.assign_attributes(needs_sync_to_ants: true)
        rdv.assign_attributes(obsolete_application_id: obsolete_application_id) if obsolete_application_id
      end
    end

    def self.enqueue_sync_for_marked_record(rdvs)
      rdvs.select(&:needs_sync_to_ants).each do |rdv|
        Ants::SyncAppointmentJob.perform_later_for(rdv)
        rdv.assign_attributes(needs_sync_to_ants: false)
      end
    end
  end
end
