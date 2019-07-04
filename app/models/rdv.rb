class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  belongs_to :user

  validates :user, :organisation, :motif, :start_at, :duration_in_min, presence: true

  after_create :send_ics_to_participants

  def end_at
    start_at + duration_in_min.minutes
  end

  def cancelled?
    cancelled_at.present?
  end

  def send_ics_to_participants
    RdvMailer.send_ics_to_user(self).deliver_later
  end

  def to_ical
    require 'icalendar'

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = start_at
      e.dtend       = end_at
      e.summary     = "RDV #{name}"
      e.description = ""
      e.sequence    = 1
    end

    cal.to_ical
  end

  def ics_name
    "rdv-#{name.parameterize}-#{start_at.to_s.parameterize}.ics"
  end

  def to_step_params
    {
      organisation: organisation,
      motif: motif,
      duration_in_min: duration_in_min,
      start_at: start_at,
      user: user,
    }
  end
end
