class Admin::Territories::MotifsController < Admin::Territories::BaseController
  before_action :set_motif, only: %i[show duplicate edit update]

  def index
    @organisations = current_territory.organisations
    @services = current_territory.services.reject(&:secretariat?)

    @motifs = policy_scope(Motif)
      .active
      .order({ name: :asc, service_id: :asc, location_type: :asc, organisation_id: :asc })
      .page(page_number)
      .per(25)
      .includes(:organisation)

    if params[:search].present?
      @motifs = @motifs.per(500)
    end

    @motifs = filter_motifs(@motifs)
    @motifs_count = @motifs.total_count
  end

  def show
    authorize(@motif)

    @duplicates = policy_scope(Motif)
      .active
      .where(service: @motif.service)
      .search_by_name_with_location_type(@motif.name_with_location_type)
      .includes(:organisation)
    @available_organisations = current_territory.organisations.order(:name) - @duplicates.map(&:organisation)
  end

  def duplicate
    orgs = Organisation.where(id: params[:organisation_ids])
    new_motifs = orgs.map do |organisation|
      new_motif = @motif.dup
      new_motif.organisation = organisation
      authorize(new_motif, :create?)
    end
    raise "ça va pas" if new_motifs.any?(&:invalid?)

    new_motifs.each(&:save!)

    flash[:success] = "Motif dupliqué dans les organisations : #{orgs.map(&:name).join(', ')}"
    redirect_to admin_territory_motif_path(current_territory, @motif)
  end

  def edit
    authorize(@motif)
  end

  def update
    authorize(@motif)
    if @motif.update(params.require(:motif).permit(*Admin::MotifsController::FORM_ATTRIBUTES))
      flash[:notice] = "Le motif a été modifié."
      redirect_to admin_territory_motifs_path(current_territory)
    else
      render :edit
    end
  end

  private

  def filter_motifs(motifs)
    motifs = motifs.search_by_text(params[:search]) if params[:search].present?
    motifs = motifs.where(organisation_id: params[:organisation_ids]) if params[:organisation_ids].present?
    motifs = motifs.where(service_id: params[:service_ids]) if params[:service_ids].present?
    motifs = motifs.where(location_type: params[:location_type]) if params[:location_type].present?
    motifs = motifs.where(collectif: params[:collectif].to_b) if params[:collectif].present?
    if params[:en_ligne].present?
      motifs = params[:en_ligne].to_b ? motifs.where.not(bookable_by: "agents") : motifs.where(bookable_by: "agents")
    end
    motifs
  end

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end
end
