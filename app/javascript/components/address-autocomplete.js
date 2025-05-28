import accessibleAutocomplete from 'accessible-autocomplete'

class AddressAutocomplete {
  constructor() {
    let status;
    function tNoResults() {
      if (status === 'loading') {
        return 'Chargement des suggestions…'
      } else if (status === 'error') {
        return 'Une erreur est survenue lors de la recherche'
      }else {
        return 'Nous n’avons pas trouvé d’adresse correspondant à votre recherche'
      }
    }

    function tStatusResults(length, contentSelectedOption) {
      const words = {
        result: (length === 1) ? 'résultat' : 'résultats',
        is: (length === 1) ? 'est' : 'sont',
        available: (length === 1) ? 'disponible' : 'disponibles'
      }

      //console.log(length, contentSelectedOption)

      return `${length} ${words.result} ${words.is} ${contentSelectedOption} ${words.available}`
    }

    function tStatusQueryTooShort(minQueryLength) {
      return `Veuillez saisir au moins ${minQueryLength} caractères pour lancer la recherche`

    }

    function source(query, populateResults) {
      if(query.length < 3) return

      status = 'loading'

      const url = "https://data.geopf.fr/geocodage/search/"
      const searchParams = new URLSearchParams()
      searchParams.append("q", query)
      searchParams.append("limit", 10)
      //if (this.addressType) searchParams.append("type", this.addressType)
      fetch(`${url}?${searchParams}`).
      then(res => res.json()).then(remapBanFeatures).then(data =>
        status = 'success' && populateResults(data, query)
      ).catch(() => status = 'error')
    }

    function remapBanFeatures(data) {
      return data.features.map(remapBanFeature)
    }

    function remapBanFeature(feature) {
      return ({
        longitude: feature.geometry.coordinates[0],
        latitude: feature.geometry.coordinates[1],
        departement: feature.properties.context.split(",")[0],
        value: getFeatureValueText(feature),
        city_code: feature.properties.citycode,
        city_name: feature.properties.city,
        ...remapBanStreetFeature(feature),
        ...feature.properties,
      })
    }

    function remapBanStreetFeature(feature) {
      if (feature.properties.type === "street") {
        return { street_ban_id: feature.properties.id, street_name: feature.properties.name }
      }
      if (feature.properties.type === "housenumber") {
        // 5 chars for city insee code, 1 for _, 4 for street fantoir
        return { street_ban_id: feature.properties.id.substring(0,10) }
      }

      return {}
    }

    function getFeatureValueText({ properties }) {
      return [properties.name].concat(getDetails(properties)).join(", ")
    }

    function getDetails({ name, city, postcode }) {
      let attributes = [postcode]
      if (name !== city) // could also check for type !== 'municipality'
        attributes.unshift(city)
      return attributes.filter(e => e)
    }

    function valueTemplate(suggestion) {
      if (!suggestion) return null

      return suggestion.value
    }

    function suggestionTemplate(suggestion) {
      const { type, name } = suggestion
      const icon = {
        housenumber: "home-4-fill",
        locality: "road-map-fill",
        municipality: "community-fill",
        street: 'map-pin-2-fill'
      }[type] || "question"
      const details = getDetails(suggestion).join(", ")
      const content = `<b>${name}</b> <span class='text-muted'>${details}</span>`
      return `
        <span class="fr-icon-${icon}"></span> ${content}
      `
    }

    function onConfirm(confirmed) {
      console.log(confirmed)

      //TODO: improve this
      document.querySelector('#search_form input[name="latitude"]').value = confirmed.latitude
      document.querySelector('#search_form input[name="longitude"]').value = confirmed.longitude
      document.querySelector('#search_form input[name="departement"]').value = confirmed.departement
      document.querySelector('#search_form input[name="city_code"]').value = confirmed.city_code
      document.querySelector('#search_form input[name="street_ban_id"]').value = confirmed.street_ban_id || ''
    }

    const element = document.querySelector('#search-address');
    const id = "autocomplete";

    accessibleAutocomplete({
      element: element,
      id: id,
      minLength: 3,
      source: source,
      inputClasses: "fr-input fr-input--lg",
      required: true,
      displayMenu: 'overlay',
      templates: {
        inputValue: valueTemplate,
        suggestion: suggestionTemplate
      },
      tNoResults: tNoResults,
      onConfirm: onConfirm,
      tStatusResults: tStatusResults,
      tStatusQueryTooShort: tStatusQueryTooShort,
    })
  }
}

export { AddressAutocomplete };