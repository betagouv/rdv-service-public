# frozen_string_literal: true

module PaperTrailHelper
  def paper_trail_change_value(property_name, value)
    # TODO: use human_attribute_value instead of these custom helpers
    return "N/A" if value.blank?
    return I18n.l(value, format: :dense) if value.is_a? Time

    property_helper = "paper_trail__#{property_name}"
    if respond_to?(property_helper, true)
      send(property_helper, value)
    else
      value.to_s
    end
  end

  private

  def paper_trail__recurrence(value)
    # NOTE: We can't use the display methods in plage_ouverture_helper because they need the whole plage_ouverture,
    # and we only have the attribute value here.
    value.to_hash.to_s
  end

  def paper_trail__user_ids(value)
    ::User.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def paper_trail__status(value)
    ::Rdv.human_attribute_value(:status, value)
  end

  def paper_trail__agent_ids(value)
    ::Agent.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def paper_trail__lieu_id(value)
    ::Lieu.find_by(id: value)&.full_name
  end

  def paper_trail__service_id(value)
    ::Service.find_by(id: value)&.name
  end

  def paper_trail__rdvs_users(values)
    values.map do |value|
      user = User.find_by(id: value["user_id"])
      next if user.nil?

      name = user.full_name
      lifecycle = RdvsUser.human_attribute_value(:send_lifecycle_notifications, value["send_lifecycle_notifications"])
      reminder = RdvsUser.human_attribute_value(:send_reminder_notification, value["send_reminder_notification"])
      status = RdvsUser.human_attribute_value(:status, value["status"])

      "#{name}: #{lifecycle}, #{reminder} - Statut : #{status}"
    end.compact.join("\n")
  end
end
