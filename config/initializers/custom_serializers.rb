# Ces serializers sont utilisés par ActiveSupport pour automatiquement
# transmettre aux jobs les attributs des absences et plages d'ouverture.

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
Rails.application.config.active_job.custom_serializers << TodSerializer

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
Rails.application.config.active_job.custom_serializers << RecurrenceSerializer
