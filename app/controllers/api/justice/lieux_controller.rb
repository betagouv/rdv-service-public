class Api::Justice::LieuxController < ActionController::Base
  def index
    # TODO: filtrer sur une colonne custom de la table territories plutôt que sur le name
    # le territory_id 3 est un territoire de test sur la prod :-/
    possible_lieux = Lieu.where(availability: :enabled).joins(organisation: :territory).where("territories.name ilike ?", "CDAD%").where.not(organisations: { territory_id: 3 }).uniq

    lieux_with_match = possible_lieux.select { |lieu| matching_ee_id_for(lieu) }

    render json: {
      match_percentage: (lieux_with_match.count * 100.0 / possible_lieux.count).round(1),
      lieux: lieux_with_match.map do |lieu|
        {
          ee_id: matching_ee_id_for(lieu),
          reservation_en_ligne: lieu.plage_ouvertures.joins(:motifs).where(motifs: { bookable_by: :everyone }).where(plage_ouvertures: { expired_cached: false }).any?,
          url: Rails.application.routes.url_helpers.public_link_to_org_url(organisation_id: lieu.organisation_id, org_slug: lieu.organisation.slug, host: URI.parse(request.url).host),
        }
      end,
    }
  end

  private

  def matching_ee_id_for(lieu)
    matching_ee_id_by_lat_long(lieu) || matching_ee_id_by_phone_and_zipcode(lieu)
  end

  def matching_ee_id_by_lat_long(lieu)
    matching_line = cdad_lieux_in_csv.find do |csv_line|
      csv_line["geo"] == "#{lieu.longitude},#{lieu.latitude}"
    end
    matching_line&.fetch("ee_id")
  end

  def matching_ee_id_by_phone_and_zipcode(lieu)
    return nil unless lieu.phone_number_formatted && lieu.address

    matching_line = cdad_lieux_in_csv.find do |csv_line|
      next unless csv_line["tel"] && csv_line["adresse"]

      Phonelib.parse(csv_line["tel"]).e164 == Phonelib.parse(lieu.phone_number).e164 && csv_line[/\d{5} /] == lieu.address[/, \d{5}/]
    end
    matching_line&.fetch("ee_id")
  end

  def cdad_lieux_in_csv
    @cdad_lieux_in_csv ||= csv_content.select do |csv_line|
      csv_line["type-organisme"].start_with?("asj-")
    end.map do |line|
      line.slice("ee_id", "geo", "tel", "adresse")
    end.tap do |_csv|
      puts "calling big select"
    end
  end

  def csv_content
    CSV.parse(raw_csv, headers: :first_row, col_sep: ";", liberal_parsing: true).map(&:to_h)
  end

  def raw_csv
    Rails.cache.fetch("justice:official_lieux_csv", expires_id: 24.hours) do
      Faraday.get("https://git.easter-eggs.org/cc-data/mj-update/-/raw/main/justice-mobile.csv?ref_type=heads").body
    end
  end
end
