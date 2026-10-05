import accessibleAutocomplete from 'accessible-autocomplete'

const DEPENDENT_INPUT_NAMES = ["departement", "latitude", "longitude", "city_code", "post_code", "city_name", "street_ban_id", "street_name"]
const MIN_QUERY_LENGTH = 3
const DEBOUNCE_DELAY = 800
const ATTRIBUTES_MANAGED_BY_AUTOCOMPLETE = ["id", "name", "class", "value", "type", "required", "placeholder", "autocomplete", "role", "data-address-autocomplete"]

// textContent insère le texte tel quel (jamais interprété comme du HTML) ;
// innerHTML le relit ensuite sérialisé, avec <, >, & échappés en &lt;, &gt;, &amp;
const escapeHtml = text => {
  const div = document.createElement("div")
  div.textContent = text
  return div.innerHTML
}

// exemple de name : 52 Avenue Jean Jaurès, city : Paris, postcode : 75019.
// District et context ont été supprimé afin de récupérer des adresses plus courtes. Exemple district: Paris 19e Arrondissement, context: 75, Paris, Île-de-France
const getDetails = ({ name, city, postcode }) => {
  let attributes = [postcode]
  if (name !== city) // could also check for type !== 'municipality'
    attributes.unshift(city)
  return attributes.filter(e => e)
}

const remapBanStreetFeature = feature => {
  if (feature.properties.type === "street") {
    return { street_ban_id: feature.properties.id, street_name: feature.properties.name }
  }
  if (feature.properties.type === "housenumber") {
    // 5 chars for city insee code, 1 for _, 4 (or more) for street fantoir
    return { street_ban_id: feature.properties.id.split("_").slice(0, 2).join("_") }
  }
  return {}
}

const remapBanFeature = feature => ({
  longitude: feature.geometry.coordinates[0],
  latitude: feature.geometry.coordinates[1],
  departement: feature.properties.context.split(",")[0],
  value: [feature.properties.name].concat(getDetails(feature.properties)).join(", "),
  city_code: feature.properties.citycode,
  city_name: feature.properties.city,
  ...remapBanStreetFeature(feature),
  ...feature.properties,
})

const tStatusResults = (length, contentSelectedOption) => {
  const words = length === 1 ? "résultat disponible" : "résultats disponibles"
  return `${length} ${words}. ${contentSelectedOption}`
}

class AddressAutocompleteInput {
  constructor(input) {
    this.addressType = input.dataset.addressType
    const form = input.closest("form")
    this.dependentInputs =
      DEPENDENT_INPUT_NAMES.
        map(name => ({ name, elt: form.querySelector(`input[name*=${name}]`)})).
        filter(i => !!i.elt) // filter only present inputs
    this.addressWithoutGeocodingInput = form.querySelector('input[type="hidden"][name*="address_without_geocoding"]')

    // accessible-autocomplete ne décore pas un input existant mais en créé un nouveau
    // On remplace donc l'input d'origine par un container, et on préserve les attributs
    const container = document.createElement("div")
    input.before(container)
    input.remove()

    accessibleAutocomplete({
      element: container,
      id: input.id,
      name: input.name,
      defaultValue: input.value,
      required: input.required,
      inputClasses: input.className,
      placeholder: input.placeholder,
      minLength: MIN_QUERY_LENGTH,
      displayMenu: "overlay",
      source: this.source,
      onConfirm: this.onConfirm,
      templates: { inputValue: this.inputValueTemplate, suggestion: this.suggestionTemplate },
      tNoResults: () => "Nous n’avons pas trouvé d’adresse correspondant à votre recherche",
      tStatusNoResults: () => "Aucun résultat",
      tStatusQueryTooShort: minLength => `Saisissez au moins ${minLength} caractères pour lancer la recherche`,
      tStatusSelectedOption: (selectedOption, length, index) => `${selectedOption} ${index + 1} sur ${length} est sélectionné`,
      tStatusResults,
      tAssistiveHint: () => "Quand des suggestions sont disponibles, utilisez les flèches haut et bas pour les parcourir et Entrée pour en choisir une. Sur un écran tactile, explorez au toucher ou par balayage.",
    })

    const autocompleteInput = container.querySelector("input")
    Array.from(input.attributes).
      filter(({ name }) => !ATTRIBUTES_MANAGED_BY_AUTOCOMPLETE.includes(name) && !name.startsWith("aria-")).
      forEach(({ name, value }) => autocompleteInput.setAttribute(name, value))

    // clear dependent fields upon input event (before selecting suggestion)
    container.addEventListener("input", () => {
      this.setDependentInputs({})
      if (this.addressWithoutGeocodingInput) this.addressWithoutGeocodingInput.value = "0"
    })
  }

  onConfirm = suggestion => {
    if (!suggestion) return

    if (suggestion.type === "no_address") {
      this.setDependentInputs({})
      if (this.addressWithoutGeocodingInput) this.addressWithoutGeocodingInput.value = "1"
    } else {
      this.setDependentInputs(suggestion)
      if (this.addressWithoutGeocodingInput) this.addressWithoutGeocodingInput.value = "0"
    }
  }

  source = (query, populateResults) => {
    clearTimeout(this.debounceTimeout)
    this.abortController?.abort()
    const trimmedQuery = query.trim()
    if (trimmedQuery.length < MIN_QUERY_LENGTH) return populateResults([])

    this.debounceTimeout = setTimeout(() => this.fetchSuggestions(trimmedQuery, populateResults), DEBOUNCE_DELAY)
  }

  fetchSuggestions = (query, populateResults) => {
    this.abortController = new AbortController() // cf https://developer.mozilla.org/en-US/docs/Web/API/AbortController
    const url = "https://data.geopf.fr/geocodage/search/"
    const searchParams = new URLSearchParams()
    searchParams.append("q", query)
    if (this.addressType) searchParams.append("type", this.addressType)
    fetch(`${url}?${searchParams}`, { signal: this.abortController.signal }).
      then(res => res.json()).
      then(data => {
        const suggestions = data.features.map(remapBanFeature)
        if (this.addressWithoutGeocodingInput) suggestions.push({ type: 'no_address', value: query })
        return suggestions
      }).
      then(populateResults).
      catch(error => {
        if (error.name !== "AbortError") throw error
      })
  }

  setDependentInputs = suggestion =>
    this.dependentInputs.forEach(({ name, elt }) => {
      elt.value = suggestion[name] || ""
    })

  inputValueTemplate = suggestion => suggestion?.value

  suggestionTemplate = suggestion => {
    if (suggestion.type === "no_address") {
      return `<span class="fr-icon-question-fill" aria-hidden="true"></span> <em class="fr-text-mention--grey">Adresse introuvable ou à l’étranger ?</em>`
    }

    const { type, name } = suggestion
    const icon = {
      housenumber: "home-4-fill",
      locality: "road-map-fill",
      municipality: "community-fill",
      street: "map-pin-2-fill"
    }[type] || "question-fill"
    const details = escapeHtml(getDetails(suggestion).join(", "))
    return `<span class="fr-icon-${icon}" aria-hidden="true"></span> <b>${escapeHtml(name)}</b> <span class="fr-text-mention--grey">${details}</span>`
  }
}

class AddressAutocomplete {
  constructor() {
    document.querySelectorAll('input[data-address-autocomplete="on"]').forEach(elt => new AddressAutocompleteInput(elt))
  }
}

export { AddressAutocomplete }
