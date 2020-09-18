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
    today = Time.zone.now.to_date
    years = today.year - user.birth_date.year
    if today.month > user.birth_date.month || (today.month == user.birth_date.month && today.day >= user.birth_date.day)
      years
    else
      years - 1
    end
  end

  def age_in_months(user)
    today = Time.zone.now.to_date
    (today.year - user.birth_date.year) * 12 + today.month - user.birth_date.month - (today.day >= user.birth_date.day ? 0 : 1)
  end

  def age_in_days(user)
    Time.zone.now.to_date - user.birth_date
  end

  def relative_tag(user)
    user.relative? ? content_tag(:span, "Proche", class: "badge badge-info") : nil
  end

  def user_soft_deleted_from_current_organisation_tag(user)
    user.organisations.include?(current_organisation) ? nil : content_tag(:span, "Supprimé", class: "badge badge-danger")
  end

  def full_name_and_birthdate(user)
    label = user.full_name
    label += " - #{birth_date_and_age(user)}" if user.birth_date
    label
  end

  def user_soft_delete_confirm_message(user)
    relatives = user.relatives.within_organisation(current_organisation).active
    [
      "Confirmez-vous la suppression de cet usager ?",
      (I18n.t("users.soft_delete_confirm_message.relatives", count: relatives.count) if relatives.any?),
    ].select(&:present?).join("\n\n")
  end

  def users_inline_list_for_agents(users, display_links_to_users: false)
    users.sort_by(&:last_name).each_with_index.reduce("") do |acc, (user, idx)|
      user_span = \
        if display_links_to_users
          user_to_link(user)
        else
          content_tag(:span, user.full_name) + relative_tag(user)
        end
      acc << (idx.positive? ? content_tag(:span, ", ") : "") + user_span
    end.html_safe
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
        content_tag(:span, user.full_name) + relative_tag(user)
      end
    else
      content_tag(:span, user.full_name) +
        relative_tag(user) +
        user_soft_deleted_from_current_organisation_tag(user)
    end
  end

  def users_to_links(users)
    safe_join(users.order_by_last_name.map { user_to_link(_1) }, ", ")
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
      "free.fr" => { url: "https://webmail.free.fr/", name: "Free Webmail" }
    }[email_tld]
  end
end
