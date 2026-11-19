class ParticipantsCsv
  def initialize(rdv)
    @rdv = rdv
  end

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ["nom complet", "adresse e-mail", "statut", "date et heure d'inscription"]
      @rdv.participations.includes(:user).order(created_at: :asc).each do |participation|
        csv << [
          participation.user.full_name,
          participation.user.email,
          Rdv.human_attribute_value(:status, participation.temporal_status, disable_cast: true),
          I18n.l(participation.created_at, format: "%d/%m/%Y %H:%M"),
        ]
      end
    end
  end

  def filename
    "participants-rdv-collectif-#{@rdv.starts_at.to_date}.csv"
  end
end
