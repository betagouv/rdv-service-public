# frozen_string_literal: true

class PlageOuverture < ApplicationRecord
  include RecurrenceConcern
  include WebhookDeliverable

  belongs_to :organisation
  belongs_to :agent
  belongs_to :lieu
  has_and_belongs_to_many :motifs, -> { distinct }

  after_save :refresh_plage_ouverture_expired_cached

  validate :end_after_start
  validates :motifs, :title, presence: true
  caution :warn_overlapping_plage_ouvertures

  has_many :webhook_endpoints, through: :organisation

  scope :expired, -> { where(expired_cached: true) }
  scope :not_expired, -> { where.not(expired_cached: true) }

  def ical_uid
    "plage_ouverture_#{id}@#{BRAND}"
  end

  def time_shift
    Tod::Shift.new(start_time, end_time)
  end

  def time_shift_duration_in_min
    time_shift.duration / 60
  end

  def self.not_expired_for_motif_name_and_lieu(motif_name, lieu)
    PlageOuverture
      .where(lieu: lieu)
      .not_expired
      .joins(:motifs)
      .where(motifs: { name: motif_name, organisation_id: lieu.organisation_id })
      .includes(:agent)
  end

  def expired?
    # Use .expired_cached? for performance
    (recurrence.nil? && first_day < Date.today) ||
      (recurrence.present? && recurrence.to_hash[:until].present? && recurrence.to_hash[:until].to_date < Date.today)
  end

  def available_motifs
    Motif.available_motifs_for_organisation_and_agent(organisation, agent)
  end

  def refresh_plage_ouverture_expired_cached
    update_column(:expired_cached, expired?)
  end

  def overlaps?(other)
    PlageOuvertureOverlap.new(self, other).exists?
  end

  def overlapping_plages_ouvertures?
    overlapping_plages_ouvertures_candidates.any? { overlaps?(_1) }
  end

  def overlapping_plages_ouvertures
    @overlapping_plages_ouvertures ||= overlapping_plages_ouvertures_candidates
      .select { overlaps?(_1) }
  end

  def self.overlapping_with_time_slot(time_slot)
    regulieres.where("first_day <= ?", time_slot.to_date)
      .or(exceptionnelles.where(first_day: time_slot.to_date))
      .to_a
      .select { _1.overlaps_with_time_slot?(time_slot) }
  end

  def overlaps_with_time_slot?(time_slot)
    covers_date?(time_slot.to_date) &&
      time_slot_for_date(time_slot.to_date).intersects?(time_slot)
  end

  def covers_date?(date)
    (
      recurring? &&
      recurrence_interval == 1 && # limited by https://github.com/rossta/montrose/pull/132
      recurrence.include?(date.in_time_zone)
    ) || (exceptionnelle? && first_day == date)
  end

  private

  def time_slot_for_date(date)
    TimeSlot.new(start_time.on(date), end_time.on(date))
  end

  def overlapping_plages_ouvertures_candidates
    return [] unless valid_date_and_times?

    candidate_pos = PlageOuverture.where(agent: agent).where.not(id: id)
      .where("recurrence IS NOT NULL or first_day >= ?", first_day)
    candidate_pos = candidate_pos.where("first_day <= ?", first_day) if exceptionnelle?
    # we could further restrict this query if perfs are an issue
    candidate_pos
  end

  def valid_date_and_times?
    [first_day, start_time, end_time].all?(&:present?)
  end

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end

  def warn_overlapping_plage_ouvertures
    return if overlapping_plages_ouvertures.empty?

    warnings.add(:base, "Conflit de dates et d'horaires avec d'autres plages d'ouvertures", active: true)
    # TODO: display richer warning messages by rendering the partial
    # overlapping_plage_ouvertures (implies passing view locals which may be tricky)
  end
end
