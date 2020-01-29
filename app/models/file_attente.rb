class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }

  scope :active, -> { joins(:rdv).where('rdvs.starts_at > ?', 7.days.from_now).order(created_at: :desc) }

  def self.send_notifications
    FileAttente.active.each do |fa|
      next unless fa.lieu.present?

      end_time = fa.last_creneau_sent_starts_at.nil? ? (fa.rdv.starts_at - 2.day) : fa.last_creneau_sent_starts_at
      date_range = Date.today..end_time.to_date
      creneaux = Creneau.for_motif_and_lieu_from_date_range(fa.rdv.motif.name, fa.lieu, date_range)
      next unless creneaux.any? && fa.notifications_sent < 10 && creneaux.first.starts_at < end_time

      fa.send_notification(creneaux.first.starts_at)
    end
  end

  def send_notification(last_creneau_sent_starts_at)
    rdv.users.map(&:user_to_notify).uniq.each do |user|
      TwilioSenderJob.perform_later(:file_attente, rdv, user) if user.formated_phone
      FileAttenteMailer.send_notification(rdv, user).deliver_later if user.email
      update!(last_creneau_sent_starts_at: last_creneau_sent_starts_at)
      increment!(:notifications_sent)
    end
  end

  def lieu
    Lieu.find_by(address: rdv.location)
  end
end
