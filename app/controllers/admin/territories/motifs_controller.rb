class Admin::Territories::MotifsController < Admin::Territories::BaseController
  def index
    @organisations = current_territory.organisations
    @services = current_territory.services.reject(&:secretariat?)

    @motifs = policy_scope(Motif)
      .active
      .order({ name: :asc, location_type: :asc, organisation_id: :asc })
      .page(page_number)
      .includes(:organisation)

    @motifs = @motifs.search_by_text(params[:search]) if params[:search].present?
    @motifs = @motifs.where(organisation_id: params[:organisation_ids]) if params[:organisation_ids].present?
    @motifs = @motifs.where(service_id: params[:service_ids]) if params[:service_ids].present?
  end
end
