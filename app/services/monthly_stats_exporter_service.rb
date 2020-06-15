class MonthlyStatsExporterService < BaseService
  include XlsExporter

  def initialize(rdvs, file)
    @rdvs = rdvs
    @file = file
  end

  def header
    ["Nombre rdv", "Service", "Département", "Mois"].freeze
  end

  def build_lines(sheet)
    counted_rdvs = count_rdv(@rdvs)
    counted_rdvs.each_with_index do |(key, rdv_quantity), index|
      row = sheet.row(index + 1)
      row.concat(row_array_from(key, rdv_quantity))
    end
  end

  def count_rdv(rdvs)
    counted_rdvs = {}
    rdvs.each do |rdv|
      key = "#{rdv.organisation.departement}-#{rdv.motif.service.name}-#{rdv.starts_at.month}"
      if counted_rdvs.keys.include?(key)
        counted_rdvs[key] += 1
      else
        counted_rdvs[key] = 1
      end
    end
    counted_rdvs
  end

  def row_array_from(key, rdv_quantity)
    departement, service, month = *key.split("-")
    [
      rdv_quantity,
      service,
      departement,
      month
    ]
  end
end
