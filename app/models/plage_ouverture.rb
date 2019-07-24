class PlageOuverture < ApplicationRecord
  require "montrose"

  serialize :start_time, Tod::TimeOfDay
  serialize :end_time, Tod::TimeOfDay
  serialize :recurrence, Montrose::Recurrence

  belongs_to :organisation
  belongs_to :pro
  has_and_belongs_to_many :motifs

  validates :title, :first_day, :start_time, :end_time, :motifs, :pro, :organisation, presence: true
  validate :end_after_start

  RECURRENCES = {
    never: Montrose.daily(total: 1).to_json,
    weekly: Montrose.weekly.to_json,
    weekly_by_2: Montrose.every(2.weeks).to_json,
  }.freeze

  scope :exceptionnelles, -> { where(recurrence: nil) }
  scope :regulieres, -> { where.not(recurrence: nil) }

  def start_at
    start_time.on(first_day)
  end

  def end_at
    end_time.on(first_day)
  end

  def occurences_for(date_range)
    recurrence_until = recurrence&.to_hash&.[](:until)
    min_until = [date_range.end, recurrence_until].compact.min.to_time.end_of_day

    if recurrence.present?
      recurrence.starting(start_at).until(min_until).lazy.select { |o| o >= date_range.begin.to_time }.to_a
    else
      [start_at].select { |t| date_range.cover?(t) }
    end
  end

  def exceptionnelle?
    recurrence.to_json == RECURRENCES[:never]
  end

  private

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end
end
