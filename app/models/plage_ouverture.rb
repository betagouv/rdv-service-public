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
  include EnsuresRealisticDate

  include TextSearch
  def self.search_against
    {
      title: "A",
      id: "D",
    }
  end

  # Attributes
  auto_strip_attributes :title

  # Relations
  belongs_to :organisation
  belongs_to :agent
  belongs_to :lieu, optional: true
  has_many :motifs_plage_ouvertures, dependent: :delete_all

  # Through relations
  has_many :webhook_endpoints, through: :organisation
  has_many :motifs, -> { distinct }, through: :motifs_plage_ouvertures

  # Validations
  validate :end_after_start
  validates :lieu, presence: true, if: -> { requires_lieu? }
  validate :lieu_is_enabled
  validates :motifs, :title, presence: true
  validate :warn_overlapping_plage_ouvertures
  validate :warn_overflow_motifs_duration

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
  scope :bookable_publicly, -> { joins(:motifs).where(motifs: { bookable_by: [:everyone] }) }

  # Delegations
  delegate :name, :address, :enabled?, to: :lieu, prefix: true, allow_nil: true
  delegate :domain, to: :organisation

  ## -

  def ical_uid
    "plage_ouverture_#{id}@#{IcalHelpers::ICS_UID_SUFFIX}"
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

  def daily_max_duration
    Tod::Shift.new(start_time, end_time).duration.seconds
  end

  def overflow_motifs_duration?
    overflow_motifs_duration.any?
  end

  def overflow_motifs_duration
    return Motif.none unless valid_date_and_times?

    motifs.where("default_duration_in_min > ?", daily_max_duration.in_minutes)
  end

  private

  def overlapping_plages_ouvertures_candidates
    return [] unless valid_date_and_times?

    candidate_pos = agent.plage_ouvertures
      .not_expired
      .where.not(id: id)

    if exceptionnelle?
      candidate_pos.regulieres.where(first_day: ..first_day)
        .or(candidate_pos.exceptionnelles.where(first_day: first_day))
    else
      candidate_pos.regulieres
        .or(candidate_pos.exceptionnelles.where(first_day: first_day..))
    end
  end

  def valid_date_and_times?
    [first_day, start_time, end_time].all?(&:present?)
  end

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, :must_be_after_start_time) if end_time <= start_time
  end

  def lieu_is_enabled
    return if lieu.blank? || lieu.enabled?

    errors.add(:lieu, :must_be_enabled)
  end

  def warn_overlapping_plage_ouvertures
    return if ignore_benign_errors

    return if overlapping_plages_ouvertures.empty?

    add_benign_error("Conflit de dates et d'horaires avec d'autres plages d'ouvertures")
    # TODO: display richer warning messages by rendering the partial
    # overlapping_plage_ouvertures (implies passing view locals which may be tricky)
  end

  def warn_overflow_motifs_duration
    return if ignore_benign_errors

    return unless overflow_motifs_duration?

    add_benign_error("Certains motifs ont une durée supérieure à la plage d'ouverture prévue")
  end

  def requires_lieu?
    motifs.any?(&:requires_lieu?)
  end
end
