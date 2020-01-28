class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }

  scope :active, -> { joins(:rdv).where('rdvs.starts_at > ?', Time.zone.now + 7.days).order(created_at: :desc) }

  def self.send_notifications
    FileAttente.active.first(10).each do |fa|
      lieu = Lieu.find_by(address: fa.rdv.location)
      next unless lieu.present?

      end_time = fa.last_creneau_sent_starts_at.nil? ? fa.rdv.starts_at : fa.last_creneau_sent_starts_at
      date_range = Time.now.to_date..end_time.to_date
      creneaux = Creneau.for_motif_and_lieu_from_date_range(fa.rdv.motif.name, lieu, date_range)
      next unless !creneaux.empty? && fa.notifications_sent < 10 && creneaux.first.starts_at < end_time

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
end
