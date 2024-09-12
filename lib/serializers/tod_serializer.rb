class TodSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a? Tod::TimeOfDay
  end

  def serialize(tod)
    super(tod_str: Tod::TimeOfDay.dump(tod))
  end

  def deserialize(hash)
    Tod::TimeOfDay.load(hash[:tod_str])
  end
end
