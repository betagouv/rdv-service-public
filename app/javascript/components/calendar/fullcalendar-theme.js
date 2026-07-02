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
  blockEventClass: "rdv-fc-block-event",
  backgroundEventClass: "rdv-fc-background-event",
  backgroundEventTitleClass: "rdv-fc-background-event-title",
}
