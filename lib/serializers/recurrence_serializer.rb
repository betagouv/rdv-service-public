class RecurrenceSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a? Montrose::Recurrence
  end

  def serialize(recurrence)
    super(recurrence_str: Montrose::Recurrence.dump(recurrence))
  end

  def deserialize(hash)
    Montrose::Recurrence.load(hash[:recurrence_str])
  end
end
