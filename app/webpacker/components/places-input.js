import "places.js";

var places = require('places.js');
class PlacesInput {
  constructor(container) {
    if (container !== null) {
      return places({
        appId: ENV.PLACES_APP_ID,
        apiKey: ENV.PLACES_API_KEY,
        countries: ['FR'],
        templates: {
          value: function(suggestion) {
            return [suggestion.name, suggestion.postcode, suggestion.city].filter(Boolean).join(" ");
          },
        },
        container: container
      }).on('change', function(e) {
        $('#lieu_latitude').val(e.suggestion.latlng.lat)
        $('#lieu_longitude').val(e.suggestion.latlng.lng)
      });
    }
  }
}

export { PlacesInput };
