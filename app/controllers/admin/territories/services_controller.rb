# frozen_string_literal: true

class Admin::Territories::ServicesController < Admin::Territories::BaseController
  before_action :set_service, except: %i[create new index]

  def index
    @services = policy_scope(Service).page(params[:page]) # creer policy scope
    @services = params[:search].present? ? @services.search_by_text(params[:search]) : @services.order(:name)
  end

  def new
    @service = Service.new
    authorize @service
  end

  def show
    authorize @service
  end

  def create
    authorize Service
    if  Service.create(service_params)
      redirect_to admin_territory_services_path()
    else
      render :new
    end
  end

  def edit
    authorize @service
  end

  def update
    authorize @service
    if @service.update(service_params)
      redirect_to admin_territory_services_path()
    else
      render :new
    end
  end

  def destroy
    authorize @service
    @service.destroy
    redirect_to admin_territory_services_path()
  end

  private

  def service_params
    params.require(:service).permit(:name, :short_name)
  end

  def set_service
    @service = Service.find(params[:id])
  end
end
