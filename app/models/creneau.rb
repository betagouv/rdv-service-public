# frozen_string_literal: true

class Creneau
  include ActiveModel::Model
  include Comparable

  attr_accessor :starts_at, :lieu_id, :motif, :agent

  delegate :full_name, to: :lieu, prefix: true, allow_nil: true

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def range
    starts_at...ends_at
  end

  def lieu
    Lieu.find(lieu_id) if lieu_id.present?
  end

  def duration_in_min
    motif.default_duration_in_min
  end

  # Required by the Comparable module
  def <=>(other)
    starts_at <=> other.starts_at
  end

  def respects_min_public_booking_delay?
    starts_at >= (Time.zone.now + motif.min_public_booking_delay.seconds)
  end

  def respects_max_public_booking_delay?
    starts_at <= (Time.zone.now + motif.max_public_booking_delay.seconds)
  end

  def respects_booking_delays?
    respects_min_public_booking_delay? && respects_max_public_booking_delay?
  end

  # Return the first event in the passed array that overlaps with the receiver
  def last_overlapping_event_ends_at(events)
    events.select do |event|
      (starts_at...ends_at).overlaps?(event.starts_at...event.ends_at) # `a...b` is the “[a, b) range” (a included, b excluded)
    end.map(&:ends_at).max
  end
end
