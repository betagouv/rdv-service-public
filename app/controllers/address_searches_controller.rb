class AddressSearchesController < ApplicationController
  layout "application_base"

  before_action do
    redirect_to root_path unless current_domain.provides_address_selection?
  end

  def index
    @address = params[:address].to_s.strip
    @prescripteur = params[:prescripteur].presence

    return if @address.blank?

    @results = GeoCoding.new.search_addresses(@address)

    selected_result = GeoCoding.auto_selectable_result(@results)
    return if selected_result.nil?

    flash[:notice] = "Adresse retenue : #{ERB::Util.html_escape(selected_result.label)}. " \
                     "#{helpers.link_to('Modifier l’adresse', root_path(address: @address, prescripteur: @prescripteur))}"
    redirect_to prendre_rdv_path(result_search_params(selected_result))
  end

  private

  def result_search_params(result)
    result.search_params.merge(prescripteur: @prescripteur).compact
  end
  helper_method :result_search_params
end
