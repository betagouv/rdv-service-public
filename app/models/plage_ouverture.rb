class PlageOuverture < ApplicationRecord
  include RecurrenceConcern
  include WebhookDeliverable

  belongs_to :organisation
  belongs_to :agent
  belongs_to :lieu
  has_and_belongs_to_many :motifs, -> { distinct }

  after_create :plage_ouverture_created
  after_save :verify_plage_ouverture_expire_date

  validate :end_after_start
  validates :motifs, :title, presence: true

  has_many :webhook_endpoints, through: :organisation

  scope :expired, -> { where(expired_cached: true) }
  scope :active, -> { where(expired_cached: false) }

  def plage_ouverture_created
    Agents::PlageOuvertureMailer.plage_ouverture_created(self).deliver_later
  end

  def ical_uid
    "plage_ouverture_#{id}@#{BRAND}"
  end

  def time_shift
    Tod::Shift.new(start_time, end_time)
  end

  def time_shift_duration_in_min
    time_shift.duration / 60
  end

  def self.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range, agent_ids = nil)
    motifs_ids = Motif.where(name: motif_name, organisation_id: lieu.organisation_id)
    results = PlageOuverture
      .includes(:motifs_plageouvertures)
      .where(lieu: lieu)
      .where("plage_ouvertures.first_day <= ?", inclusive_date_range.end)
      .joins(:motifs)
      .where(motifs: { id: motifs_ids })
      .includes(:motifs, agent: :absences)

    if agent_ids.present?
      results = results.where(agent_id: agent_ids)
    end

    results.uniq
  end

  def expired?
    # Use .expired_cached? for performance
    (recurrence.nil? && first_day < Date.today) && (recurrence.present? && recurrence.until < Date.today)
  end

  def available_motifs
    Motif.available_motifs_for_organisation_and_agent(organisation, agent)
  end

  def verify_plage_ouverture_expire_date
    is_expired = expired? ? true : false
    self.update_column(:expired_cached, is_expired)
  end

  private

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end
end
