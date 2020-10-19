module FromRdvParams
  extend ActiveSupport::Concern

  def set_resources_from_rdv_params
    @motif = Motif.find(params["motif_id"]) if params && params["motif_id"].present?
    @starts_at = Time.parse(params["starts_at"]) if params && params["starts_at"].present?
    @lieu = Lieu.find(params["lieu_id"]) if params && params["lieu_id"].present?
  end
end
