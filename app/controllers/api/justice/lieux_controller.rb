class Api::Justice::LieuxController < ActionController::Base
  def index
    # TODO: filtrer sur une colonne custom de la table territories plutôt que sur le name
    # le territory_id 3 est un territoire de test sur la prod :-/
    possible_lieux = Lieu.where(availability: :enabled).joins(organisation: :territory).where("territories.name ilike ?", "CDAD%").where.not(organisations: { territory_id: 3 })

    lieux_with_match = possible_lieux.select { |lieu| matching_ee_id_for(lieu) }

    render json: {
      lieux: lieux_with_match.map do |lieu|
        {
          ee_id: matching_ee_id_for(lieu),
          reservation_en_ligne: lieu.joins(plage_ouvertures: :motifs).where(motifs: { bookable_by: :everyone }).where(plage_ouvertures: { expired_cached: false }).any?,
          url: Rails.application.routes.url_helpers.public_link_to_org_url(oragnisation_id: lieu.organisation_id, org_slug: lieu.organisation.slug),
        }
      end,
    }
  end

  private

  def matching_ee_id(lieu)
    csv_content.find do |csv_line|
      csv_line["geo"] == "#{lieu.longitude},#{lieu.latitude}"
    end
  end

  def csv_content
    @csv_content ||= CSV.parse(raw_csv, headers: :first_row, col_sep: ";", liberal_parsing: true)
  end

  def raw_csv
    Rails.cache.fetch("justice:official_lieux_csv", expires_id: 24.hours) do
      Faraday.get("https://git.easter-eggs.org/cc-data/mj-update/-/raw/main/justice-mobile.csv?ref_type=heads").body
    end
  end
end
