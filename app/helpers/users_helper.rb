# frozen_string_literal: true

module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{I18n.l(user.birth_date)} - #{age(user)}"
  end

  def age(user)
    years = age_in_years(user)
    return "#{years} ans" if years >= 3

    months = age_in_months(user)
    return "#{months} mois" if months.positive?

    "#{age_in_days(user).to_i} jours"
  end

  def age_in_years(user)
    today = Time.zone.today
    years = today.year - user.birth_date.year
    if today.month > user.birth_date.month || (today.month == user.birth_date.month && today.day >= user.birth_date.day)
      years
    else
      years - 1
    end
  end

  def age_in_months(user)
    today = Time.zone.today
    ((today.year - user.birth_date.year) * 12) + today.month - user.birth_date.month - (today.day >= user.birth_date.day ? 0 : 1)
  end

  def age_in_days(user)
    Time.zone.today - user.birth_date
  end

  def relative_tag(user)
    user.relative? ? tag.span("Proche", class: "badge badge-info") : nil
  end

  def user_logged_franceconnect_tag(user)
    user.logged_once_with_franceconnect? ? tag.span("FranceConnect", class: "badge badge-info") : nil
  end

  def user_not_in_org_tag(organisation, user)
    return if organisation.territory.visible_users_throughout_the_territory?

    tag.span("Supprimé de cette organisation", class: "badge badge-danger") unless user.profile_for(organisation)
  end

  def full_name_and_birthdate(user)
    user.full_name + birth_date_and_age_if_exist(user)
  end

  def reverse_full_name_and_birthdate(user)
    user.reverse_full_name + birth_date_and_age_if_exist(user)
  end

  def birth_date_and_age_if_exist(user)
    return " - #{birth_date_and_age(user)}" if user.birth_date

    ""
  end

  def notify_by_email_description(user)
    if user.responsible_email.blank?
      "🔴 pas d'email renseigné"
    elsif user.responsible_notify_by_email?
      "🟢 Activées"
    else
      "🔴 Désactivées"
    end
  end

  def clickable_user_email(user)
    user.responsible_email.present? ? mail_to(user.responsible_email) : nil
  end

  def notify_by_sms_description(user)
    if user.responsible_phone_number.blank?
      "🔴 pas de numéro de téléphone renseigné"
    elsif !user.responsible_phone_number_mobile?
      "🔴 le numéro de téléphone renseigné n'est pas un mobile"
    elsif user.responsible_notify_by_sms?
      "🟢 Activées"
    else
      "🔴 Désactivées"
    end
  end

  def clickable_user_phone_number(user)
    user.responsible_phone_number.present? ? link_to(user.responsible_phone_number, "tel:#{user.responsible_or_self.phone_number_formatted}") : nil
  end

  def formatted_user_notes(user)
    user.notes.present? ? simple_format(user.notes) : nil
  end

  def user_destroy_confirm_message(user)
    relatives = user.relatives.merge(current_organisation.users)
    [
      "Confirmez-vous la suppression de cet usager ?",
      (I18n.t("users.destroy_confirm_message.relatives", count: relatives.size) if relatives.any?),
    ].select(&:present?).join("\n\n")
  end

  def users_inline_list_for_agents(users, display_links_to_users: false)
    safe_join(users.sort_by(&:last_name).map do |user|
      if display_links_to_users
        user_to_link(user)
      else
        tag.span(user.full_name) + relative_tag(user)
      end
    end, ", ")
  end

  def users_to_sentence(users)
    # only used in user space
    users.select do |user|
      user == current_user || current_user.relatives.include?(user)
    end.map(&:full_name).sort.to_sentence
  end

  def user_to_link(user)
    if user.organisations.include?(current_organisation)
      link_to admin_organisation_user_path(current_organisation, user) do
        tag.span(user.full_name) + relative_tag(user)
      end
    else
      tag.span(user.full_name) +
        relative_tag(user) +
        user_not_in_org_tag(current_organisation, user)
    end
  end

  def email_tld_infos(email_tld)
    {
      "gmail.com" => { url: "https://mail.google.com", name: "GMail" },
      "hotmail.fr" => { url: "https://outlook.live.com/", name: "Hotmail" },
      "hotmail.com" => { url: "https://outlook.live.com/", name: "Hotmail" },
      "outlook.fr" => { url: "https://outlook.live.com/", name: "Outlook" },
      "outlook.com" => { url: "https://outlook.live.com/", name: "Outlook" },
      "live.fr" => { url: "https://rms.orange.fr/mail/inbox", name: "Orange" },
      "laposte.net" => { url: "https://www.laposte.net/accueil", name: "Laposte.net" },
      "yahoo.fr" => { url: "https://fr.mail.yahoo.com", name: "Yahoo Mail" },
      "yahoo.com" => { url: "https://mail.yahoo.com", name: "Yahoo Mail" },
      "sfr.fr" => { url: "https://webmail.sfr.fr", name: "SFR Mail" },
      "free.fr" => { url: "https://webmail.free.fr/", name: "Free Webmail" },
    }[email_tld]
  end

  def default_service_selection_from(source)
    return :relative if source.respond_to?(:pmi?) && source.pmi?
    return :relative if source.respond_to?(:relative?) && source.relative?

    :responsible
  end

  def user_merge_attribute_value(user, attribute)
    return birth_date_and_age(user) if attribute == :birth_date
    return user.responsible&.full_name if attribute == :responsible_id
    return formatted_user_notes(user) if attribute == :notes
    return user&.human_attribute_value(:logement) if attribute == :logement

    user.send(attribute)
  end
end
