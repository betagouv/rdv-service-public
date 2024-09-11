# Ces serializers sont utilisés par ActiveSupport pour automatiquement
# transmettre aux jobs les attributs des absences et plages d'ouverture.

class TodSerializer < ActiveJob::Serializers::ObjectSerializer
  # Checks if an argument should be serialized by this serializer.
  def serialize?(argument)
    argument.is_a? Tod::TimeOfDay
  end

  # Converts an object to a simpler representative using supported object types.
  # The recommended representative is a Hash with a specific key. Keys can be of basic types only.
  # You should call `super` to add the custom serializer type to the hash.
  def serialize(tod)
    super(tod_str: Tod::TimeOfDay.dump(tod))
  end

  # Converts serialized value into a proper object.
  def deserialize(hash)
    Tod::TimeOfDay.load(hash[:tod_str])
  end
end

Rails.application.config.active_job.custom_serializers << TodSerializer

class RecurrenceSerializer < ActiveJob::Serializers::ObjectSerializer
  # Checks if an argument should be serialized by this serializer.
  def serialize?(argument)
    argument.is_a? Montrose::Recurrence
  end

  # Converts an object to a simpler representative using supported object types.
  # The recommended representative is a Hash with a specific key. Keys can be of basic types only.
  # You should call `super` to add the custom serializer type to the hash.
  def serialize(recurrence)
    super(recurrence_str: Montrose::Recurrence.dump(recurrence))
  end

  # Converts serialized value into a proper object.
  def deserialize(hash)
    Montrose::Recurrence.load(hash[:recurrence_str])
  end
end

Rails.application.config.active_job.custom_serializers << RecurrenceSerializer
