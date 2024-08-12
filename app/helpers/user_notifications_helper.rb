module UserNotificationsHelper
  def user_notifiable_by_sms_text(user)
    notif_details = 
      if user.phone_number.blank?
        nil
      elsif !user.phone_number_mobile?
        "impossibles car le numéro n'est pas mobile"
      else
        user.notify_by_sms? ? "activées" : "désactivées"
      end
    number_tag = tag.b(user.phone_number.presence || "Non renseigné")
    details_tag = notif_details ? tag.span("(notifications par SMS #{notif_details})") : ""
    safe_join([number_tag, " ", details_tag])
  end
end
