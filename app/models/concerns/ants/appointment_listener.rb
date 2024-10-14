module Ants
  module AppointmentListener
    extend ActiveSupport::Concern

    ATTRIBUTES_TO_WATCH = %w[id status starts_at lieu_id].freeze

    included do
      attr_accessor :needs_sync_to_ants, :obsolete_application_id

      Rdv.before_commit do |rdv|
        Ants::AppointmentListener.mark_for_sync([rdv]) if rdv.watching_attributes_for_ants_api_changed?
      end
      User.before_commit do |user|
        Ants::AppointmentListener.mark_for_sync(user.rdvs) if user.saved_change_to_ants_pre_demande_number?
      end
      Participation.before_commit do |participation|
        Ants::AppointmentListener.mark_for_sync([participation.rdv], obsolete_application_id: participation.user.ants_pre_demande_number)
      end
      Lieu.before_commit do |lieu|
        Ants::AppointmentListener.mark_for_sync(lieu.rdvs) if lieu.saved_change_to_name?
      end

      Rdv.after_commit do |rdv|
        Ants::AppointmentListener.enqueue_sync_for_marked_record([rdv]) if rdv.watching_attributes_for_ants_api_changed?
      end
      User.after_commit do |user|
        Ants::AppointmentListener.enqueue_sync_for_marked_record(user.rdvs) if user.saved_change_to_ants_pre_demande_number?
      end
      Participation.after_commit do |participation|
        Ants::AppointmentListener.enqueue_sync_for_marked_record([participation.rdv])
      end
      Lieu.after_commit do |lieu|
        Ants::AppointmentListener.enqueue_sync_for_marked_record(lieu.rdvs) if lieu.saved_change_to_name?
      end
    end

    def watching_attributes_for_ants_api_changed?
      saved_changes.keys & ATTRIBUTES_TO_WATCH
    end

    def self.mark_for_sync(rdvs, obsolete_application_id: nil)
      rdvs.each do |rdv|
        next unless rdv.requires_ants_predemande_number?

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
