# frozen_string_literal: true

class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }

  NO_MORE_NOTIFICATIONS = 7.days
  MAX_NOTIFICATIONS = 3

  scope :with_upcoming_rdvs, -> { joins(:rdv).where("rdvs.starts_at > ?", NO_MORE_NOTIFICATIONS.from_now).order(created_at: :desc) }
  scope :for_organisation, lambda { |organisation|
    joins(:rdv).where(rdvs: { organisation: organisation })
  }

  def self.send_notifications
    FileAttente.with_upcoming_rdvs.each do |fa|
      next if fa.rdv.motif.phone?

      end_time = fa.rdv.starts_at - 2.days
      date_range = Date.today..end_time.to_date
      creneaux = fa.rdv.creneaux_available(date_range)
      next unless fa.valid_for_notification?(creneaux)

      fa.send_notification
    end
  end

  def valid_for_notification?(creneaux)
    !creneaux.empty? && notifications_sent < MAX_NOTIFICATIONS && (last_creneau_sent_at.nil? || last_creneau_sent_at.to_date < Date.today)
  end

  def send_notification
    rdv.users.map(&:user_to_notify).uniq.each do |user|
      if user.notifiable_by_sms?
        SendTransactionalSmsJob.perform_later(:file_attente, rdv.id, user.id)
        rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :file_attente_creneaux_available)
      end

      next unless user.notifiable_by_email?

      Users::FileAttenteMailer.new_creneau_available(rdv, user).deliver_later if
      update!(notifications_sent: notifications_sent + 1, last_creneau_sent_at: Time.zone.now)
      rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :file_attente_creneaux_available)
    end
  end
end
