class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }

  scope :active, -> { joins(:rdv).where('rdvs.starts_at > ?', Time.zone.now + 7.days).order(created_at: :desc) }

  def self.send_notifications
    FileAttente.active.first(10).each do |fa|
      lieu = Lieu.find_by(address: fa.rdv.location)
      next unless lieu.present?

      end_date = fa.last_creneau_sent_starts_at.nil? ? fa.rdv.starts_at.to_date : fa.last_creneau_sent_starts_at.to_date
      date_range = Time.now.to_date..end_date
      creneaux = Creneau.for_motif_and_lieu_from_date_range(fa.rdv.motif.name, lieu, date_range)
      next unless !creneaux.empty? && fa.notifications_sent < 10 && creneaux.first.starts_at != fa.last_creneau_sent_starts_at

      fa.rdv.users.map(&:user_to_notify).uniq.each do |user|
        FileAttenteJob.perform_later(user, fa.rdv)
        fa.update(last_creneau_sent_starts_at: creneaux.first.starts_at)
        fa.increment!(:notifications_sent)
      end
    end
  end
end
