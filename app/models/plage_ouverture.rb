class PlageOuverture < ApplicationRecord
  # Mixins
  has_paper_trail
  include RecurrenceConcern
  include WebhookDeliverable
  include IcsPayloads::PlageOuverture
  include Expiration

  include TextSearch
  def self.search_options
    {
      against:
        {
          title: "A",
          id: "D",
        },
      ignoring: :accents,
      using: { tsearch: { prefix: true } },
    }
  end

  # Attributes
  auto_strip_attributes :title

  attribute :afternoon_start_time, :time_only # uses Tod::TimeOfDayType
  attribute :afternoon_end_time,   :time_only # uses Tod::TimeOfDayType

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
  validate :afternoon_times_valid
  validates :lieu, presence: true, if: -> { requires_lieu? }
  validate :lieu_is_enabled
  validates :motifs, presence: true
  validate :warn_overlapping_plage_ouvertures
  validate :warn_overflow_motifs_duration
  validates :first_day, realistic_date: true
  validates :recurrence_ends_at, realistic_date: true

  # Scopes
  scope :in_range, lambda { |range|
    return all if range.nil?

    not_recurring_start_in_range = where(recurrence: nil).where(first_day: range)
    # This tsrange expression is indexed on plage_ouvertures
    recurring_in_range = where.not(recurrence: nil).where("tsrange(first_day, recurrence_ends_at, '[]') && tsrange(?, ?)", range.begin, range.end)

    not_recurring_start_in_range.or(recurring_in_range)
  }
  scope :bookable_by_everyone, -> { joins(:motifs).merge(Motif.bookable_by_everyone) }
  scope :bookable_by_everyone_or_bookable_by_invited_users, -> { joins(:motifs).merge(Motif.bookable_by_everyone_or_bookable_by_invited_users) }

  # Delegations
  delegate :name, :address, :enabled?, to: :lieu, prefix: true, allow_nil: true
  delegate :domain, to: :organisation

  ## -

  def afternoon_starts_at
    return nil if afternoon_start_time.blank? || first_day.blank?

    afternoon_start_time&.on(first_day)
  end

  def afternoon_ends_at
    if recurring?
      raise "cette méthode n'a de sens que pour les plages exceptionnelles"
    elsif afternoon_end_time && first_day
      afternoon_end_time&.on(first_day)
    end
  end

  def title_with_default
    if title.present?
      title
    elsif starts_at && ends_at
      "Plage de #{human_time_range}"
    else
      "Plage d'ouverture"
    end
  end

  def ical_uid
    "plage_ouverture_#{id}@#{IcalFormatters::Ics::ICS_UID_SUFFIX}"
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

  def afternoon_times_valid
    return unless afternoon_start_time && afternoon_end_time

    if afternoon_start_time >= afternoon_end_time
      errors.add(:afternoon_end_time, :must_be_after_afternoon_start_time)
    end

    return unless start_time && end_time

    first_interval = start_time..end_time
    second_interval = afternoon_start_time..afternoon_end_time
    if first_interval.overlaps?(second_interval)
      errors.add(:afternoon_start_time, :overlaps_primary_interval)
    end
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
