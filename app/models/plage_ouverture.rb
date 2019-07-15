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

  def start_at
    first_day + start_time.hour.hours + start_time.min.minutes
  end

  def end_at
    first_day + end_time.hour.hours + end_time.min.minutes
  end

  def occurences
    if recurrence.present?
      recurrence.starting(start_at)
    else
      [start_at] # Test ?? same class ?
    end
  end

  private

  def end_after_start
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end
end
