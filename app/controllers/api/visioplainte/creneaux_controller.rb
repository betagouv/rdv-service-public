class Api::Visioplainte::CreneauxController < Api::Visioplainte::BaseController
  def index
    motif = find_motif(params[:service])

    render json: {
      creneaux: creneaux(motif).map do |creneau|
        {
          starts_at: creneau.starts_at.iso8601,
          duration_in_min: motif.default_duration_in_min,
        }
      end,
    }
  end

  private

  def date_range
    @date_range ||= (Date.parse(params[:date_debut])..Date.parse(params[:date_fin]))
  end

  def creneaux(motif)
    Users::CreneauxSearch.new(
      lieu: nil,
      user: nil,
      motif: motif,
      date_range: date_range
    ).creneaux
  end

  def find_motif(service)
    motifs = Motif.joins(:organisation).where(organisation: { territory_id: ENV["VISIOPLAINTE_TERRITORY_ID"] }).joins(:service)

    case service
    when "Police"
      motifs.find_by(service: { name: "Police Nationale" })
    when "Gendarmerie"
      motifs.find_by(service: { name: "Gendarmerie Nationale" })
    else
      raise "unknown service"
    end
  end
end
