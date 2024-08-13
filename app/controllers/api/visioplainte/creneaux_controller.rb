class Api::Visioplainte::CreneauxController < Api::Visioplainte::BaseController
  def index
    render json: {
      creneaux: [
        {
          starts_at: "2024-12-22T10:00:00+02:00",
          duration_in_min: 30,
        },
        {
          starts_at: "2024-12-22T10:30:00+02:00",
          duration_in_min: 30,
        },
        {
          starts_at: "2024-12-22T11:00:00+02:00",
          duration_in_min: 30,
        },
      ],
    }
  end
end
