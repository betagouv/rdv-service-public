# frozen_string_literal: true

module RdvsUserExporter
  HourFormat = Spreadsheet::Format.new(number_format: "hh:mm")
  DateFormat = Spreadsheet::Format.new(number_format: "DD/MM/YYYY")
  HEADER = [
    "usager",
    "rdv_id",
    "année",
    "date prise rdv",
    "heure prise rdv",
    "origine",
    "date rdv",
    "heure rdv",
    "service",
    "motif",
    "contexte",
    "statut",
    "lieu",
    "professionnel.le(s)",
    "commune du responsable",
    "usager mineur ?",
    "résultat des notifications",
    "Organisation",
    "date naissance",
    "code postal du responsable",
    "créé par",
    "email(s) professionnel.le(s)",
  ].freeze

  def self.export(rdv_users)
    extract_string_from(build_excel_workbook_from(rdv_users))
  end

  def self.extract_string_from(workbook)
    file = StringIO.new
    workbook.write(file)
    file.string
  end

  def self.build_excel_workbook_from(rdv_users)
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat(HEADER)

    rdv_users = rdv_users.includes(
      user: :responsible,
      rdv: [
        :organisation,
        :agents,
        :lieu,
        :receipts,
        :versions_where_event_eq_create,
        :users,
        { motif: :service },
      ]
    )

    rdv_users.find_each.with_index do |rdv_user, index|
      row = sheet.row(index + 1)
      row.set_format 3, DateFormat
      row.set_format 4, HourFormat
      row.set_format 6, DateFormat
      row.set_format 7, HourFormat

      row.concat(row_array_from(rdv_user))
    end
    book
  end

  def self.row_array_from(rdv_user)
    rdv = rdv_user.rdv
    user = rdv_user.user
    [
      user.full_name,
      rdv.id,
      rdv.created_at.year,
      I18n.l(rdv.created_at.to_date),
      I18n.l(rdv.created_at, format: :time_only),
      rdv.human_attribute_value(:created_by),
      I18n.l(rdv.starts_at.to_date),
      I18n.l(rdv.starts_at, format: :time_only),
      rdv.motif.service.name,
      rdv.motif_name,
      rdv.context,
      Rdv.human_attribute_value(:status, rdv.temporal_status, disable_cast: true),
      rdv.address_without_personal_information || "",
      rdv.agents.map(&:full_name).join(", "),
      user.user_to_notify.city_name,
      user.minor? ? "oui" : "non",
      Receipt.human_attribute_value(:result, rdv.synthesized_receipts_result),
      rdv.organisation.name,
      user.birth_date.present? ? I18n.l(user.birth_date) : "",
      extract_postal_code_from(user.user_to_notify.address),
      rdv.author,
      rdv.agents.map(&:email).join(", "),
    ]
  end

  def self.extract_postal_code_from(address)
    return "" if address.blank?

    postal_code = address.match(/.*([0-9]{5}).*/)
    return "" if postal_code.blank? || postal_code.captures.empty?

    postal_code.captures.first
  end
end
