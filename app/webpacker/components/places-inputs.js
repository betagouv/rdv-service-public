import 'autocomplete.js/dist/autocomplete.jquery.js'
import 'custom-event-polyfill'
import 'whatwg-fetch'


class PlacesInput {
  constructor(container) {
    if (container === null) return false;

    this.addressType = container.dataset.addressType;
    const form = $(container).closest('form')[0];
    this.dependentInputs =
      ["departement", "latitude", "longitude", "city_code", "city_name", "street_ban_id", "street_name"].
        map(name => ({ name, elt: form.querySelector(`input[name*=${name}]`)})).
        filter(i => !!i.elt) // filter only present inputs

    $(container).autocomplete(
      { hint: false },
      [{
        source: this.getSuggestions,
        debounce: 100,
        templates: { suggestion: this.suggestionTemplate }
      }]
    ).on('autocomplete:selected', (_event, suggestion, _dataset, _context) =>
      this.setDependentInputs(suggestion)
    );

    // clear dependent fields upon input event (before selecting suggestion)
    container.addEventListener("input", () => this.setDependentInputs({}))
  }

  getSuggestions = (query, callback) => {
    const url = "https://api-adresse.data.gouv.fr/search/"
    const searchParams = new URLSearchParams()
    searchParams.append("q", query)
    if (this.addressType) searchParams.append("type", this.addressType)
    fetch(`${url}?${searchParams}`).
      then(res => res.json()).
      then(this.remapBanFeatures).
      then(callback)
  }

  remapBanFeatures = data => data.features.map(this.remapBanFeature)

  remapBanFeature = feature => ({
    longitude: feature.geometry.coordinates[0],
    latitude: feature.geometry.coordinates[1],
    departement: feature.properties.context.split(",")[0],
    value: this.getFeatureValueText(feature),
    city_code: feature.properties.citycode,
    city_name: feature.properties.city,
    ...this.remapBanStreetFeature(feature),
    ...feature.properties,
  })

  remapBanStreetFeature = feature => {
    if (feature.properties.type === "street") {
      return { street_ban_id: feature.properties.id }
    }
    if (feature.properties.type === "housenumber") {
      // 5 chars for city insee code, 1 for _, 4 for street fantoir
      return { street_ban_id: feature.properties.id.substring(0,10) }
    }

    return {}
  }

  getFeatureValueText = ({ properties }) => {
    return [properties.name].concat(this.getDetails(properties)).join(", ")
  }

  setDependentInputs = suggestion =>
    this.dependentInputs.forEach(({ name, elt }) => {
      elt.value = suggestion[name] || ""
      elt.dispatchEvent(new CustomEvent("change")) // not triggered automatically
    })

  suggestionTemplate = suggestion => {
    const { type, name } = suggestion
    const icon = {
      housenumber: "map-marker",
      locality: "map-pin",
      municipality: "city",
      street: 'road'
    }[type] || "question"
    const details = this.getDetails(suggestion).join(", ")
    const content = `<b>${name}</b> <span class='text-muted'>${details}</span>`
    return `
      <div class='d-flex'>
        <div class='ml-1'><i class="fa fa-${icon}"></i></div>
        <div class='ml-1'>${content}</div>
      </div>
    `
  }

  getDetails = ({ name, city, postcode, district, context }) => {
    let attributes = [postcode, district, context]
    if (name !== city) // could also check for type !== 'municipality'
      attributes.unshift(city)
    return attributes.filter(e => e)
  }
}

class PlacesInputs {
  constructor() {
    document.querySelectorAll('.places-js-container').forEach(elt => new PlacesInput(elt))
  }
}


export { PlacesInputs };
