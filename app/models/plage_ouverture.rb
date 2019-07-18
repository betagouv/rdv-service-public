class PlageOuverture < ApplicationRecord
  require "montrose"

  serialize :start_time, Tod::TimeOfDay
  serialize :end_time, Tod::TimeOfDay
  serialize :recurrence, Montrose::Recurrence

  belongs_to :organisation
  belongs_to :pro
  has_and_belongs_to_many :motifs

  validates :title, :first_day, :start_time, :end_time, :motifs, :pro, :organisation, :recurrence, presence: true
  validate :end_after_start

  RECURRENCES = {
    never: Montrose.daily(total: 1).to_json,
    weekly: Montrose.weekly.to_json,
    weekly_by_2: Montrose.every(2.weeks).to_json,
  }.freeze

  scope :exceptionnelles, -> { where(recurrence: RECURRENCES[:never]) }
  scope :regulieres, -> { where.not(recurrence: RECURRENCES[:never]) }

  def start_at
    first_day + start_time.hour.hours + start_time.min.minutes
  end

  def end_at
    first_day + end_time.hour.hours + end_time.min.minutes
  end

  def occurences_until(until_date)
    return nil if until_date.nil?

    recurrence.starting(start_at).until(until_date).to_a
  end

  private

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end
end
