import 'autocomplete.js/dist/autocomplete.jquery.js'

class PlacesInput {
  constructor(container) {
    if (container === null) return false;

    const form = container.closest('form');
    this.dependentInputs =
      ["departement", "latitude", "longitude"].
        map(name => ({ name, elt: form.querySelector(`input[name*=${name}]`)})).
        filter(i => !!i.elt) // filter only present inputs

    $(container).autocomplete(
      { hint: false },
      [{
        source: this.getSuggestions,
        displayKey: 'label',
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
    fetch(`${url}?${searchParams}`).
      then(res => res.json()).
      then(this.remapBanFeatures).
      then(callback)
  }

  remapBanFeatures = data => data.features.map(this.remapBanFeature)

  remapBanFeature = feature => ({
    latitude: feature.geometry.coordinates[0],
    longitude: feature.geometry.coordinates[1],
    departement: feature.properties.context.split(",")[0],
    ...feature.properties,
  })

  setDependentInputs = suggestion =>
    this.dependentInputs.forEach(({ name, elt }) => {
      elt.value = suggestion[name] || ""
      elt.dispatchEvent(new Event("change")) // not triggered automatically
    })

  suggestionTemplate = suggestion => {
    const icon = {
      housenumber: "map-marker",
      locality: "map-pin",
      municipality: "city",
      street: 'road'
    }[suggestion.type] || "question"
    return `
      <div class='d-flex'>
        <div class='ml-1'><i class="fa fa-${icon}"></i></div>
        <div class='ml-1'>${this.suggestionContent(suggestion)}</div>
      </div>
    `
  }

  suggestionContent = suggestion => {
    const { label, type, name, district, context } = suggestion
    if (["housenumber", "street"].indexOf(type) >= 0) {
      const details = [district, context].filter(e => e).join(" ")
      return `<b>${name}</b> <span class='text-muted'>${details}</span>`
    }
    return label
  }
}

export { PlacesInput };
