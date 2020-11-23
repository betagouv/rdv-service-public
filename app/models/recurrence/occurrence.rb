class Recurrence::Occurrence
  include ActiveModel::Model
  include Comparable

  attr_accessor :starts_at, :ends_at

  def <=>(other)
    starts_at <=> other.starts_at
  end

  def to_date
    starts_at.to_date
  end
end
