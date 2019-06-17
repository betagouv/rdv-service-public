class SitesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation

  def new
    @site = Site.new(organisation: @organisation)
    authorize(@site)
    respond_right_bar_with @site
  end

  def create
    @site = Site.new(organisation: @organisation)
    @site.assign_attributes(site_params)
    authorize(@site)
    flash.notice = "Site créé" if @site.save
    respond_right_bar_with @site, location: @site.organisation
  end

  def edit
    @site = policy_scope(Site).find(params[:id])
    authorize(@site)
    respond_right_bar_with @site
  end

  def update
    @site = Site.find(params[:id])
    authorize(@site)
    if @site.update(site_params)
      redirect_to @site.organisation, notice: "Site modifié"
    else
      render :edit
    end
  end

  def destroy
    @site = Site.find(params[:id])
    authorize(@site)
    if @site.destroy
      redirect_to @site.organisation, notice: 'Site supprimé'
    else
      render :edit
    end
  end

  private

  def site_params
    params.require(:site).permit(:name, :address, :horaires, :telephone)
  end
end
