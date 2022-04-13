# frozen_string_literal: true

class PlageOuverture < ApplicationRecord
  # Mixins
  has_paper_trail
  include RecurrenceConcern
  include WebhookDeliverable
  include IcalHelpers::Ics
  include IcalHelpers::Rrule
  include Payloads::PlageOuverture
  include Expiration
  include TextSearch
  def self.search_keys = %i[title]

  # Attributes
  auto_strip_attributes :title

  # Relations
  belongs_to :organisation
  belongs_to :agent
  belongs_to :lieu
  has_and_belongs_to_many :motifs, -> { distinct }

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  # Validations
  validate :end_after_start
  validate :lieu_is_enabled
  validates :motifs, :title, presence: true
  validate :warn_overlapping_plage_ouvertures

  # Scopes
  scope :in_range, lambda { |range|
    return all if range.nil?

    not_recurring_start_in_range = where(recurrence: nil).where(first_day: range)
    # This tsrange expression is indexed on plage_ouvertures
    recurring_in_range = where.not(recurrence: nil).where("tsrange(first_day, recurrence_ends_at, '[]') && tsrange(?, ?)", range.begin, range.end)

    not_recurring_start_in_range.or(recurring_in_range)
  }
  scope :overlapping_range, lambda { |range|
    in_range(range).select do |plage_ouverture|
      plage_ouverture.occurrences_for(range).any? { range.overlaps?(_1.starts_at.._1.ends_at) }
    end
  }

  ## -

  def ical_uid
    "plage_ouverture_#{id}@#{BRAND}"
  end

  def available_motifs
    Motif.available_motifs_for_organisation_and_agent(organisation, agent).individuel
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

  def covers_date?(date)
    if recurring?
      recurrence.include?(date.in_time_zone)
    else
      first_day == date
    end
  end

  private

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

  def lieu_is_enabled
    errors.add(:lieu, :must_be_enabled) unless lieu&.enabled?
  end

  def warn_overlapping_plage_ouvertures
    return if ignore_benign_errors

    return if overlapping_plages_ouvertures.empty?

    add_benign_error("Conflit de dates et d'horaires avec d'autres plages d'ouvertures")
    # TODO: display richer warning messages by rendering the partial
    # overlapping_plage_ouvertures (implies passing view locals which may be tricky)
  end
end
