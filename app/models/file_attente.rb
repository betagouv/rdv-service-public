# frozen_string_literal: true

class FileAttente < ApplicationRecord
  # Constants
  NO_MORE_NOTIFICATIONS = 7.days
  MAX_NOTIFICATIONS = 3

  # Relations
  belongs_to :rdv
  belongs_to :user

  # Validations
  validates :rdv, uniqueness: { scope: :user }

  # Scopes
  scope :with_upcoming_rdvs, -> { joins(:rdv).where("rdvs.starts_at > ?", NO_MORE_NOTIFICATIONS.from_now).order(created_at: :desc) }

  ## -

  def self.send_notifications
    FileAttente.with_upcoming_rdvs.each do |fa|
      next if fa.rdv.motif.phone?

      end_time = fa.rdv.starts_at - 2.days
      date_range = Time.zone.today..end_time.to_date
      creneaux = fa.rdv.creneaux_available(date_range)
      next unless fa.valid_for_notification?(creneaux)

      fa.send_notification
    end
  end

  def valid_for_notification?(creneaux)
    !creneaux.empty? && notifications_sent < MAX_NOTIFICATIONS && (last_creneau_sent_at.nil? || last_creneau_sent_at.to_date < Time.zone.today)
  end

  def send_notification
    rdv.users.map(&:user_to_notify).uniq.each do |user|
      invitation_token = invitation_token_for(rdv, user) if user.notifiable_by_sms? || user.notifiable_by_email?

      if user.notifiable_by_sms?
        Users::FileAttenteSms.new_creneau_available(rdv, user, invitation_token).deliver_later
      end

      next unless user.notifiable_by_email?

      Users::FileAttenteMailer.with(rdv: rdv, user: user, token: invitation_token).new_creneau_available.deliver_later
      update!(notifications_sent: notifications_sent + 1, last_creneau_sent_at: Time.zone.now)

      params = {
        rdv: rdv,
        user: user,
        event: :new_creneau_available,
        channel: :mail,
        result: :processed,
        email_address: user.email,
      }
      Receipt.create!(params)
    end
  end

  def invitation_token_for(rdv, user)
    RdvsUser.find_by(rdv: rdv, user: user)&.new_raw_invitation_token
  end
end
