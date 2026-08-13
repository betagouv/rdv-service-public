class FileAttente < ApplicationRecord
  has_paper_trail

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
  scope :with_remaining_notifications, -> { where("notifications_sent < ?", MAX_NOTIFICATIONS) }

  ## -

  def send_notification_if_valid
    return if rdv.motif.phone?
    return unless valid_for_notification?

    send_notification
  end

  private

  def valid_for_notification?
    next_availability.present? && next_availability.starts_at < end_time && (last_creneau_sent_at.nil? || last_creneau_sent_at.to_date < Time.zone.today)
  end

  def end_time
    rdv.starts_at - 2.days
  end

  def next_availability
    @next_availability ||= CreneauxSearch::ForUser.new(
      user: rdv.users.first,
      motif: rdv.motif,
      lieu: rdv.lieu,
      duration_in_min: rdv.duration_in_min,
      date_range: Time.zone.today..end_time.to_date
    ).next_availability
  end

  def send_notification
    rdv.users.map(&:user_to_notify).uniq.each do |user|
      next unless user.notifiable_by_sms? || user.notifiable_by_email?

      invitation_token = invitation_token_for(rdv, user)

      ActiveRecord::Base.transaction do
        if user.notifiable_by_sms?
          Users::FileAttenteSms.new_creneau_available(rdv, user).deliver_later
        end

        if user.notifiable_by_email?
          Users::FileAttenteMailer.with(rdv: rdv, user: user, token: invitation_token).new_creneau_available.deliver_later

          Receipt.create!(
            rdv: rdv,
            user: user,
            event: :new_creneau_available,
            channel: :mail,
            result: :processed,
            email_address: user.email
          )
        end

        update!(notifications_sent: notifications_sent + 1, last_creneau_sent_at: Time.zone.now)
      end
    end
  end

  def invitation_token_for(rdv, user)
    participation = user.participation_for(rdv)
    return nil unless participation

    participation.restricted_auth_token
  end
end
