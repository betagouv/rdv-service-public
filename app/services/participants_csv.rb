class ParticipantsCsv
  def initialize(rdv)
    @rdv = rdv
  end

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ["nom complet", "adresse e-mail", "statut"]
      @rdv.participations.includes(:user).order(created_at: :asc).each do |participation|
        csv << [
          participation.user.full_name,
          participation.user.email,
          Rdv.human_attribute_value(:status, participation.temporal_status, disable_cast: true),
        ]
      end
    end
  end

  def filename
    "participants-rdv-collectif-#{@rdv.starts_at.to_date}.csv"
  end
end
