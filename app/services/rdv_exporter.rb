# frozen_string_literal: true

module RdvExporter
  HourFormat = Spreadsheet::Format.new(number_format: "hh:mm")
  DateFormat = Spreadsheet::Format.new(number_format: "DD/MM/YYYY")
  HEADER = [
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
    "usager(s)",
    "commune du premier responsable",
    "au moins un usager mineur ?",
    "résultat des notifications",
    "Organisation",
    "date naissance",
    "code postal du premier responsable",
    "créé par",
    "email(s) professionnel.le(s)",
  ].freeze

  def self.export(rdvs)
    extract_string_from(build_excel_workbook_from(rdvs))
  end

  def self.extract_string_from(workbook)
    file = StringIO.new
    workbook.write(file)
    file.string
  end

  def self.build_excel_workbook_from(rdvs)
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat(HEADER)

    rdvs = rdvs.includes(
      :organisation,
      :agents,
      :lieu,
      :receipts,
      :versions_where_event_eq_create,
      motif: :service,
      users: :responsible
    )

    rdvs.find_each.with_index do |rdv, index|
      row = sheet.row(index + 1)
      row.set_format 1, DateFormat
      row.set_format 2, HourFormat
      row.set_format 4, DateFormat
      row.set_format 5, HourFormat

      row.concat(row_array_from(rdv))
    end
    book
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.row_array_from(rdv)
    [
      rdv.created_at.year,
      I18n.l(rdv.created_at.to_date),
      I18n.l(rdv.created_at, format: :time_only),
      rdv.human_attribute_value(:created_by),
      I18n.l(rdv.starts_at.to_date),
      I18n.l(rdv.starts_at, format: :time_only),
      rdv.motif.service.name,
      rdv.motif.name,
      rdv.context,
      Rdv.human_attribute_value(:status, rdv.temporal_status, disable_cast: true),
      rdv.address_without_personal_information || "",
      rdv.agents.map(&:full_name).join(", "),
      rdv.users.map(&:full_name).join(", "),
      commune_premier_responsable(rdv),
      rdv.users.any?(&:minor?) ? "oui" : "non",
      Receipt.human_attribute_value(:result, rdv.synthesized_receipts_result),
      rdv.organisation.name,
      rdv.users.map(&:birth_date).compact.map { |date| I18n.l(date) }.join(", "),
      code_postal_premier_responsable(rdv),
      rdv.author,
      rdv.agents.map(&:email).join(", "),
    ]
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.commune_premier_responsable(rdv)
    rdv.users.map(&:user_to_notify).pluck(:city_name).compact.first
  end

  def self.code_postal_premier_responsable(rdv)
    address = rdv.users.map(&:user_to_notify).pluck(:address).compact.first
    extract_postal_code_from(address) if address.present?
  end

  def self.extract_postal_code_from(address)
    postal_code = address.match(/.*([0-9]{5}).*/)
    return "" if postal_code.blank? || postal_code.captures.empty?

    postal_code.captures.first
  end
end
