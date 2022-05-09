# frozen_string_literal: true

# rails runner scripts/recycle_old_rdv_events_to_receipts.rb

# Limits
monitoring_start_date = Receipt.minimum(:created_at) # 2022-04-12
oldest_known_rdv = Rdv.minimum(:starts_at) # Rdvs are deleted after two years, cf DestroyOldRdvsJob

# Attributes mapping:
type_to_channel = { notification_sms: "sms", notification_mail: "mail" }
event_name_to_event = {
  # We don’t need to distinguish between cancelled_by_user/cancelled_by_agent, because Rdv#status has different values for :excused and :revoked.
  # It was not the case initially.
  cancelled_by_user: :rdv_cancelled,
  cancelled_by_agent: :rdv_cancelled,
  file_attente_creneaux_available: :new_creneau_available,
  created: :rdv_created,
  updated: :rdv_date_updated,
  upcoming_reminder: :rdv_upcoming_reminder
}

# Do everything in a large transaction; errors raised will cancel it all.
Receipt.transaction do
  old_events = RdvEvent.where(created_at: oldest_known_rdv..monitoring_start_date)
  count = old_events.count
  puts "#{count} RdvEvents to recycle…"
  old_events.find_in_batches do |batch|
    converted_attributes = batch.map do |event|
      {
        rdv_id: event.rdv_id,
        event: event_name_to_event[event.event_name.to_sym],
        channel: type_to_channel[event.event_type.to_sym],
        result: :processed,
        created_at: event.created_at,
        updated_at: event.created_at
      }
      # We don’t have a user_id; RdvEvent used to be sent to all users;
      # We also don’t have content, sms_phone_number or email_address,
      # as well as sms_provider, sms_count, content and error_message.
    end
    Receipt.insert_all!(converted_attributes) # rubocop:disable Rails/SkipsModelValidations
    count -= batch.count
    puts "#{count} …"
  end
  puts "Done."
end
