class Users::ContactableOrganisations
  def initialize(organisation_ids, motif_category_short_name)
    @organisation_ids = organisation_ids
    @motif_category_short_name = motif_category_short_name
  end

  def organisations
    @organisations ||= Organisation.where(id: @organisation_ids).contactable
  end

  def organisations_emails
    organisations.where.not(email: [nil, ""]).pluck(:email).join(",")
  end

  def motif_category_name
    @motif_category_short_name.present? ? MotifCategory.find_by(short_name: @motif_category_short_name)&.name : nil
  end
end
