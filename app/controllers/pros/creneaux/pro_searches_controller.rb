class Pros::Creneaux::ProSearchesController < DashboardAuthController
  respond_to :html, :js

  def index
    skip_policy_scope
    respond_to do |format|
      format.html
      format.js do
        @pro_search = Creneau::ProSearch.new(filter_params)
        set_params
        @lieux = @pro_search.lieux

        @creneaux_by_lieux = @lieux.each_with_object({}) do |lieu, creneaux_by_lieux|
          creneaux_by_lieux[lieu.id] = Creneau.for_motif_and_lieu_from_date_range(@motif.name, lieu, @date_range, true, @pro_ids)
        end
      end
    end
  end

  def by_lieu
    skip_authorization

    @pro_search = Creneau::ProSearch.new(by_lieu_params)
    set_params
    @lieu = @pro_search.lieu

    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif.name, @lieu, @date_range, true, @pro_ids)
  end

  def set_params
    @date_range = @pro_search.from_date..(@pro_search.from_date + 6.days)
    @motif = @pro_search.motif
    @pro_ids = @pro_search.pro_ids
  end

  private

  def filter_params
    params.require(:creneau_pro_search).permit(:lieu_id, :motif_id, :from_date, pro_ids: [])
  end

  def by_lieu_params
    params.permit(:lieu_id, :motif_id, :from_date, pro_ids: [])
  end
end
