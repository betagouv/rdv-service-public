class Recurrence::Occurrence
  include ActiveModel::Model
  include Comparable

  attr_accessor :starts_at, :ends_at

  def <=>(other)
    starts_at <=> other.starts_at
  end

  delegate :to_date, to: :starts_at

  def overlaps?(range)
    # Pour des intervalles de temps consécutifs, nous ne considérons pas qu'il y a conflit des horaires
    # (8..9).overlapping_range?(9..10) => False
    return false if range.first == ends_at || range.last == starts_at

    range.overlaps?(starts_at..ends_at)
  end
end
