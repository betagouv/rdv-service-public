class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }

  STOP_NOTIFICATIONS = 7.days

  scope :active, -> { joins(:rdv).where('rdvs.starts_at > ?', STOP_NOTIFICATIONS.from_now).order(created_at: :desc) }

  def self.send_notifications
    FileAttente.active.each do |fa|
      next unless fa.lieu.present?
      end_time = fa.last_creneau_sent_starts_at.nil? ? (fa.rdv.starts_at - 2.day) : fa.last_creneau_sent_starts_at
      date_range = Date.today..end_time.to_date
      creneaux = Creneau.for_motif_and_lieu_from_date_range(fa.rdv.motif.name, fa.lieu, date_range)
      creneau = creneaux.select{|c| fa.rdv.motif.min_booking_delay.seconds < (c.starts_at - Time.now).seconds }.first
      next unless fa.valid_for_notification?(creneau, end_time)

      fa.send_notification(creneaux.first.starts_at)
    end
  end

  def valid_for_notification?(creneau, end_time)
    creneau.present? && notifications_sent < 5 && creneau.starts_at.to_date < end_time.to_date
  end

  def send_notification(last_creneau_sent_starts_at)
    rdv.users.map(&:user_to_notify).uniq.each do |user|
      TwilioSenderJob.perform_later(:file_attente, rdv, user) if user.formated_phone
      FileAttenteMailer.send_notification(rdv, user).deliver_later if user.email
      update!(last_creneau_sent_starts_at: last_creneau_sent_starts_at, notifications_sent: notifications_sent + 1)
    end
  end

  def lieu
    Lieu.find_by(address: rdv.location)
  end
end
