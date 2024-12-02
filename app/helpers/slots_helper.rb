module SlotsHelper
  def extract_uniq_slots_for_date_and_time(slots, date)
    slots.sort_by(&:starts_at).uniq(&:starts_at).group_by { |c| c.starts_at.to_date }.select { |k, _v| k == date }
  end

  def search_rdv_slot_url_with(user)
    if user.present?
      admin_organisation_creneaux_search_path(current_organisation, user_ids: [user.id])
    else
      admin_organisation_creneaux_search_path(current_organisation)
    end
  end
end
