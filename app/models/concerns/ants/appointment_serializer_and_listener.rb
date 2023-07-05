# frozen_string_literal: true

module Ants
  module AppointmentSerializerAndListener
    extend ActiveSupport::Concern

    ATTRIBUTES_TO_WATCH = %w[id status starts_at lieu_id].freeze

    included do
      attr_accessor :needs_sync_to_ants

      User.before_commit do |user|
        if user.saved_change_to_ants_pre_demande_number?
          Ants::SyncAppointmentJob.perform_later(user.ants_pre_demande_number_was)
          Ants::AppointmentSerializerAndListener.mark_for_sync([user])
        end
      end
      RdvsUser.before_commit do |rdv_user|
        Ants::AppointmentSerializerAndListener.mark_for_sync([rdv_user.user])
      end
      Rdv.before_commit do |rdv|
        Ants::AppointmentSerializerAndListener.mark_for_sync(rdv.users) if rdv.saved_changes.keys & ATTRIBUTES_TO_WATCH
      end

      User.after_commit do |user|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record([user]) if user.saved_change_to_ants_pre_demande_number?
      end
      RdvsUser.after_commit do |rdv_user|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record([rdv_user.user])
      end
      Rdv.after_commit do |rdv|
        Ants::AppointmentSerializerAndListener.enqueue_sync_for_marked_record(rdv.users) if rdv.saved_changes.keys & ATTRIBUTES_TO_WATCH
      end

      Lieu.after_commit do |lieu|
        if lieu.saved_change_to_name?
          updated_users = User.joins(:rdvs).where(rdvs: { lieu_id: lieu.id }).where.not(ants_pre_demande_number: [nil, ""]).where("rdvs.starts_at > ?", Time.zone.now)
          updated_users.each do |user|
            Ants::SyncAppointmentJob.perform_later_for(user)
          end
        end
      end
    end

    def self.serialize_for_ants_api(ants_pre_demande_number, rdv)
      AntsApi::Appointment.new(
        application_id: ants_pre_demande_number,
        meeting_point: rdv.lieu.name,
        appointment_date: rdv.starts_at,
        management_url: Rails.application.routes.url_helpers.users_rdv_url(rdv.id, host: Domain::RDV_MAIRIE.host_name)
      )
    end

    def self.mark_for_sync(users)
      users.each do |user|
        user.assign_attributes(needs_sync_to_ants: true)
      end
    end

    def self.enqueue_sync_for_marked_record(users)
      users.select(&:needs_sync_to_ants).each do |user|
        Ants::SyncAppointmentJob.perform_later(user.ants_pre_demande_number)
        user.assign_attributes(needs_sync_to_ants: false)
      end
    end
  end
end
