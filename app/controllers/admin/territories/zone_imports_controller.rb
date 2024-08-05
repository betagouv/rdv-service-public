class Admin::Territories::ZoneImportsController < Admin::Territories::BaseController
  def new
    authorize_agent Zone.new(sector: Sector.new(territory: current_territory))
    @form = ZoneImportForm.new
  end

  def create
    authorize_agent Zone.new(sector: Sector.new(territory: current_territory))
    @form = ZoneImportForm.new(import_params)
    if @form.valid?
      @res = ImportZoneRowsService.perform_with(
        CsvOrXlsReader::Importer.new(@form.zones_file).rows,
        current_territory,
        current_agent,
        dry_run: @form.dry_run
      )
    else
      render :new
    end
  rescue CsvOrXlsReader::FileFormatError => e
    flash.now[:error] = e.message
    render :new
  end

  private

  def pundit_user
    agent
  end

  def import_params
    params
      .require(:zone_import)
      .permit(:zones_file, :dry_run)
  end
end
