//= require jquery
//= require jquery_ujs
//= require selectize
//= require moment
//= require datetime_picker
//= require places.js/dist/cdn/places.min
//= require_tree .

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
  container: document.querySelector('.places-js-container')
});