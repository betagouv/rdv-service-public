# frozen_string_literal: true

class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :lieu_id, :motif, :agent_id

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def range
    starts_at...ends_at
  end

  def lieu
    Lieu.find(lieu_id)
  end

  def agent
    Agent.find(agent_id)
  end

  def duration_in_min
    motif.default_duration_in_min
  end

  def respects_min_booking_delay?
    starts_at >= (Time.zone.now + motif.min_booking_delay.seconds)
  end

  def respects_max_booking_delay?
    starts_at <= (Time.zone.now + motif.max_booking_delay.seconds)
  end

  def respects_booking_delays?
    respects_min_booking_delay? && respects_max_booking_delay?
  end

  # Return the first event in the passed array that overlaps with the receiver
  def last_overlapping_event_ends_at(events)
    events.select do |event|
      (starts_at...ends_at).overlaps?(event.starts_at...event.ends_at) # `a...b` is the “[a, b) range” (a included, b excluded)
    end.map(&:ends_at).max
  end

  def overlaps_jour_ferie?
    OffDays.all_in_date_range(starts_at.to_date..ends_at.to_date).any?
  end
end
