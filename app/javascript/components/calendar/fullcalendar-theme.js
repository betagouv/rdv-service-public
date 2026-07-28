// Thème custom RDV Service Public pour FullCalendar v7.
// En v7, un thème est un simple objet d'options *Class/*Content à spread dans la config Calendar.
// Les classes ici sont nos propres noms stables — indépendants des noms obfusqués du thème "classic".
// Voir : https://v7.fullcalendar.io/custom-themes

export const rdvTheme = {
  toolbarTitleClass: "rdv-fc-toolbar-title fr-h6",
  buttonClass: "rdv-fc-button",
  // hasSelection est true pour le groupe des sélecteurs de vue (Mois/Semaine/…),
  // false pour les groupes de navigation (Aujourd'hui/</>)
  buttonGroupClass: (info) => info.hasSelection ? "rdv-fc-view-group" : "rdv-fc-nav-group",
  eventClass: "rdv-fc-event",
  blockEventClass: "rdv-fc-block-event",
  blockEventTimeClass: "rdv-fc-event-time",
  backgroundEventClass: "rdv-fc-background-event",
  backgroundEventTitleClass: "rdv-fc-background-event-title",
  // FC v7 classic wraps column header inner text in aria-hidden (the accessible name
  // is already on the outer [role="columnheader"] via aria-label). axe's
  // empty-table-header rule requires visible text, not just aria-label, so we remove
  // aria-hidden from the inner wrapper as each header is mounted.
  dayHeaderDidMount: ({ el }) => {
    el.querySelectorAll('[aria-hidden]').forEach(inner => inner.removeAttribute('aria-hidden'))
  },
  // FC v7 renders [role="rowheader"][aria-label="Timed"] as an empty element.
  // Add a visually-hidden span so axe finds text content inside the header.
  viewDidMount: ({ el }) => {
    el.querySelectorAll('[role="rowheader"]').forEach(header => {
      if (!header.textContent.trim()) {
        const span = document.createElement('span')
        span.className = 'fr-sr-only'
        span.textContent = header.getAttribute('aria-label')
        header.appendChild(span)
      }
    })
  },
}
