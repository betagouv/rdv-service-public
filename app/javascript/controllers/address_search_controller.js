import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_DELAY_MS = 500
const MIN_QUERY_LENGTH = 3
const RESULTS_LIMIT = 5
// Au-delà de ce délai, on annonce aussi la recherche en cours aux technologies d'assistance.
// En deçà, on évite de les interrompre à chaque pause dans la saisie.
const SLOW_SEARCH_ANNOUNCEMENT_DELAY_MS = 1000

// Connects to data-controller="address-search"
// Amélioration progressive de la recherche d'adresse : pendant la saisie, le navigateur interroge directement
// l'API de géocodage et affiche les adresses sous le bouton « Rechercher ». Le focus reste dans le champ
// et le nombre de résultats est annoncé via une zone de statut.
// Sans JS, le formulaire et la page de résultats (géocodage côté serveur) fonctionnent seuls.
export default class extends Controller {
  static targets = ["form", "input", "results", "status", "loading", "listTemplate", "itemTemplate", "emptyTemplate", "errorTemplate"]
  static values = { geocodingUrl: String, bookingUrl: String }

  disconnect() {
    clearTimeout(this.debounceTimeout)
    clearTimeout(this.slowSearchTimeout)
    this.abortController?.abort()
  }

  search() {
    clearTimeout(this.debounceTimeout)
    const queryLength = this.query().length
    // Retour visuel immédiat, sans attendre la fin du debounce
    this.setPending(queryLength === 0 || queryLength >= MIN_QUERY_LENGTH)
    this.debounceTimeout = setTimeout(() => this.loadResults(), DEBOUNCE_DELAY_MS)
  }

  async loadResults() {
    const query = this.query()

    if (query.length === 0) {
      this.abortController?.abort()
      this.lastQuery = null
      this.resultsTarget.replaceChildren()
      this.statusTarget.textContent = ""
      this.setPending(false)
      return
    }
    if (query.length < MIN_QUERY_LENGTH) return
    if (query === this.lastQuery) {
      this.setPending(false)
      return
    }

    this.abortController?.abort()
    this.abortController = new AbortController()
    this.lastQuery = query
    this.slowSearchTimeout = setTimeout(() => this.announce("Recherche des adresses en cours…"), SLOW_SEARCH_ANNOUNCEMENT_DELAY_MS)

    try {
      const url = new URL(this.geocodingUrlValue)
      url.search = new URLSearchParams({ q: query, limit: RESULTS_LIMIT }).toString()
      const response = await fetch(url, { signal: this.abortController.signal })
      if (!response.ok) throw new Error(`Géocodage en erreur : ${response.status}`)

      const { features } = await response.json()
      this.renderResults(query, features.map(banFeatureToAddress))
    } catch (error) {
      if (error.name === "AbortError") return

      this.lastQuery = null
      this.renderError()
    }
  }

  renderResults(query, addresses) {
    if (addresses.length === 0) {
      const summary = `Aucune adresse ne correspond à « ${query} »`
      this.render(this.emptyTemplateTarget, summary, `${summary}.`)
      return
    }

    const summary = addresses.length === 1 ?
      `1 adresse correspond à « ${query} »` :
      `${addresses.length} adresses correspondent à « ${query} »`
    this.render(this.listTemplateTarget, summary, `${summary}. Résultats listés après le bouton Rechercher.`)
    const list = this.resultsTarget.querySelector("ul")
    addresses.forEach(address => list.appendChild(this.renderItem(address)))
  }

  renderItem(address) {
    const item = this.itemTemplateTarget.content.cloneNode(true)
    const link = item.querySelector("a")
    link.textContent = address.label
    link.href = this.bookingUrl(address)
    return item
  }

  renderError() {
    this.render(this.errorTemplateTarget, null, "La recherche automatique n’a pas abouti. Utilisez le bouton Rechercher.")
  }

  // Le contenu provenant de l'API ou de la saisie est toujours inséré via textContent
  render(template, summary, announcement) {
    const content = template.content.cloneNode(true)
    const summaryElement = content.querySelector("[data-address-search-summary]")
    if (summaryElement) summaryElement.textContent = summary
    this.resultsTarget.replaceChildren(content)
    this.setPending(false)
    this.announce(announcement)
  }

  bookingUrl({ label, departement, cityCode, streetBanId, latitude, longitude }) {
    const url = new URL(this.bookingUrlValue, window.location.origin)
    const params = {
      address: label,
      departement,
      city_code: cityCode,
      street_ban_id: streetBanId,
      latitude,
      longitude,
      prescripteur: new FormData(this.formTarget).get("prescripteur"),
    }
    Object.entries(params).forEach(([key, value]) => {
      if (value !== null && value !== undefined) url.searchParams.append(key, value)
    })
    return url.toString()
  }

  setPending(pending) {
    if (!pending) clearTimeout(this.slowSearchTimeout)
    this.loadingTarget.hidden = !pending
    this.resultsTarget.setAttribute("aria-busy", pending)
   
  }

  // On vide la zone avant de la remplir pour qu'un message identique au précédent soit bien restitué
  announce(message) {
    this.statusTarget.textContent = ""
    setTimeout(() => { this.statusTarget.textContent = message }, 100)
  }

  query() {
    return this.inputTarget.value.trim()
  }
}

// Même logique que GeoCoding#address_result côté serveur
const banFeatureToAddress = ({ geometry, properties }) => {
  const { name, city, postcode, citycode, context, type, id } = properties
  const details = name === city ? [postcode] : [city, postcode]
  const [longitude, latitude] = geometry.coordinates

  let streetBanId = null
  if (type === "street") streetBanId = id
  // 5 caractères pour le code insee de la commune, 1 pour _, 4 (ou plus) pour le code fantoir de la voie
  if (type === "housenumber") streetBanId = id.split("_").slice(0, 2).join("_")

  return {
    label: [name, ...details].filter(Boolean).join(", "),
    departement: context.split(",")[0],
    cityCode: citycode,
    streetBanId,
    latitude,
    longitude,
  }
}
