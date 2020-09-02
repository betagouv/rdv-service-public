class Admin::Departements::ZoneImportsController < AgentDepartementAuthController
  def new
    authorize(current_organisation)
    @form = ZoneImportForm.new
  end

  def create
    authorize(current_organisation)
    @form = ZoneImportForm.new(import_params)
    if @form.valid?
      @res = ImportZoneRowsService.perform_with(
        CsvOrXlsReader::Importer.new(@form.zones_file).rows,
        current_departement.number,
        current_agent,
        dry_run: @form.dry_run,
        override_conflicts: @form.override_conflicts
      )
    else
      render :new
    end
  end

  private

  def import_params
    params
      .require(:zone_import)
      .permit(:zones_file, :dry_run, :override_conflicts)
  end
end
