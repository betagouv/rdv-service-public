# frozen_string_literal: true

class Admin::Territories::ZoneImportsController < Admin::Territories::BaseController
  def new
    authorize_admin(Zone.new(sector: Sector.new(territory: current_territory)))
    @form = ZoneImportForm.new
  end

  def create
    authorize_admin(Zone.new(sector: Sector.new(territory: current_territory)))
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
  end

  private

  def import_params
    params
      .require(:zone_import)
      .permit(:zones_file, :dry_run)
  end
end
