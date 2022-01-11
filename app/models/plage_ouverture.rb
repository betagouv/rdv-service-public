# frozen_string_literal: true

class PlageOuverture < ApplicationRecord
  include RecurrenceConcern
  include WebhookDeliverable
  include IcalHelpers::Ics
  include IcalHelpers::Rrule
  include Payloads::PlageOuverture
  include Expiration

  auto_strip_attributes :title

  belongs_to :organisation
  belongs_to :agent
  belongs_to :lieu
  has_and_belongs_to_many :motifs, -> { distinct }

  validate :end_after_start
  validates :motifs, :title, presence: true
  validate :warn_overlapping_plage_ouvertures

  has_many :webhook_endpoints, through: :organisation

  scope :in_range, lambda { |range|
    return all if range.nil?

    not_recurring_start_in_range = where(recurrence: nil).where(first_day: range)
    # This tsrange expression is indexed on plage_ouvertures
    recurring_in_range = where.not(recurrence: nil).where("tsrange(first_day, recurrence_ends_at, '[]') && tsrange(?, ?)", range.begin, range.end)

    not_recurring_start_in_range.or(recurring_in_range)
  }

  def ical_uid
    "plage_ouverture_#{id}@#{BRAND}"
  end

  def time_shift
    Tod::Shift.new(start_time, end_time)
  end

  def time_shift_duration_in_min
    time_shift.duration / 60
  end

  def available_motifs
    Motif.available_motifs_for_organisation_and_agent(organisation, agent)
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
    if recurring?
      recurrence.include?(date.in_time_zone)
    else
      first_day == date
    end
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

    errors.add(:end_time, :must_be_after_start_time) if end_time <= start_time
  end

  def warn_overlapping_plage_ouvertures
    return if ignore_benign_errors

    return if overlapping_plages_ouvertures.empty?

    add_benign_error("Conflit de dates et d'horaires avec d'autres plages d'ouvertures")
    # TODO: display richer warning messages by rendering the partial
    # overlapping_plage_ouvertures (implies passing view locals which may be tricky)
  end
end
