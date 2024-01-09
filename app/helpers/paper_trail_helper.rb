module PaperTrailHelper
  def paper_trail_change_value(property_name, value)
    # TODO: use human_attribute_value instead of these custom helpers
    return "N/A" if value.blank?

    if respond_to?("paper_trail__#{property_name}", true)
      return send("paper_trail__#{property_name}", value)
    end

    if property_name.ends_with?("_at")
      return I18n.l(Time.zone.parse(value), format: :dense)
    elsif property_name.ends_with?("_day") || property_name.ends_with?("_date")
      return I18n.l(Date.parse(value), format: :long)
    end

    value.to_s
  end

  private

  def paper_trail__status(value)
    ::Rdv.human_attribute_value(:status, value)
  end

  def paper_trail__lieu_id(value)
    ::Lieu.find_by(id: value)&.full_name
  end

  def paper_trail__service_id(value)
    ::Service.find_by(id: value)&.name
  end

  def paper_trail__participations(values)
    values.map do |value|
      user = User.find_by(id: value["user_id"])
      next if user.nil?

      name = user.full_name
      lifecycle = Participation.human_attribute_value(:send_lifecycle_notifications, value["send_lifecycle_notifications"])
      reminder = Participation.human_attribute_value(:send_reminder_notification, value["send_reminder_notification"])
      status = Participation.human_attribute_value(:status, value["status"])
      created_by = Participation.human_attribute_value(:created_by, value["created_by"])

      "#{name} (#{created_by}): #{lifecycle}, #{reminder} - Statut : #{status}"
    end.compact.join("\n")
  end
end
