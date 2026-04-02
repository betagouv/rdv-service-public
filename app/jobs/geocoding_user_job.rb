class GeocodingUserJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    return if user.address.blank?

    result = GeoCoding.new.get_geolocation_results(user.address)
    return unless result

    user.update!(result.slice(:city_code, :post_code, :city_name))
  end
end
