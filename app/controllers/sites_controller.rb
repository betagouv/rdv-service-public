class SitesController < DashboardAuthController
  before_action :set_organisation

  def new
    @site = Site.new(organisation: @organisation)
    authorize(@site)
  end

  def create
    @site = Site.new(organisation: @organisation)
    @site.assign_attributes(site_params)
    authorize(@site)
    if @site.save
      flash.notice = "Site créé"
      redirect_to @site.organisation
    else
      render :edit
    end
  end

  def edit
    @site = Site.find(params[:id])
    authorize(@site)
  end

  def update
    @site = Site.find(params[:id])
    authorize(@site)
    if @site.update(site_params)
      flash.notice = "Site modifié"
      redirect_to @site.organisation
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

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def site_params
    params.require(:site).permit(:name, :address)
  end
end
