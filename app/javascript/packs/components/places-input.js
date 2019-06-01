import "places.js";

var places = require('places.js');

class PlacesInput {
  constructor(container) {
    if (container !== null) {
      places({
        type: 'address',
        appId: env.placesAppId,
        apiKey: env.placesApiKey,
        countries: ['FR'],
        templates: {
          value: function(suggestion) {
            return suggestion.name + ', ' + suggestion.postcode + ' ' + suggestion.city ;
          },
        },
        container: container
      });
    }
  }
}

export { PlacesInput };
