class PlageOuverture < ApplicationRecord
  require "montrose"

  serialize :start_time, Tod::TimeOfDay
  serialize :end_time, Tod::TimeOfDay
  serialize :recurrence, Montrose::Recurrence

  belongs_to :organisation
  belongs_to :pro
  belongs_to :lieu
  has_and_belongs_to_many :motifs

  before_save :clear_empty_recurrence

  validate :end_after_start

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
    recurrence.nil?
  end

  private

  def clear_empty_recurrence
    self.recurrence = nil if recurrence.present? && recurrence.to_hash == {}
  end

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end
end
