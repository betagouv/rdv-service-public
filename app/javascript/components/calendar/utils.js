import frLocale from '@fullcalendar/core/locales/fr';
import { getConsumer, destroyConsumer } from "../../cable/consumer";

export const betaPlanningEnabled = () => {
  return !!document.querySelector('main[data-beta-planning-layout="true"]');
};

export const betaHeaderToolbarLayout = { left: "today,prev,next,title", center: "dayGridMonth,timeGridWeek,timeGridOneDay,listWeek", right: "preferencesModalToggle" };
export const classicHeaderToolbarLayout = { center: "dayGridMonth,timeGridWeek,timeGridOneDay,listWeek" };

export const betaWeekTitleFormat = { month: "long", year: "numeric" };

export const preferencesModalToggle = {
  text: "Préférences d’affichage",
  click: () => { window.dsfr(document.getElementById("agenda-preferences-modal")).modal.disclose(); },
};

const CUSTOM_HEADER_FORMATS = {
  timeGridWeek: { weekday: "short", day: "numeric" },
  timeGridOneDay: { weekday: "short", day: "numeric" },
  dayGridMonth: { weekday: "long" },
  resourceTimeGridWeek: { weekday: "short", day: "numeric" },
};
export const dayHeaderContent = ({ date, view }) => {
  if(betaPlanningEnabled()) {
    if (CUSTOM_HEADER_FORMATS[view.type]) {
      return new Intl.DateTimeFormat('fr-FR', CUSTOM_HEADER_FORMATS[view.type]).format(date);
    }
  }
  // else : on retourne null et FullCalendar utilise le formateur par défaut
};

// On empêche de sélectionner plusieurs jours car ce n'est pas actuellement
// pertinent ni pour les RDV ni pour les plages d'ouverture.
const canSelectOnlyOneDay = (selectInfo) => {

  // vue mensuelle (dayGridMonth)
  if (selectInfo.allDay) {
    // Quand on clique sur un seul jour, FullCalendar nous fournit un interval d'exactement 24h.
    return selectInfo.end - selectInfo.start === 24 * 60 * 60 * 1000;
  }

  // vue hebdo / quotidienne (timeGrid___)
  else {
    const startDate = selectInfo.startStr.slice(0, 10);
    const endDate = selectInfo.endStr.slice(0, 10);
    return startDate === endDate;
  }

};

export const hiddenDays = ({ displaySaturdays, displaySundays }) => {
  const hiddenDays = []
  if (displaySaturdays !== "true") {
    hiddenDays.push(6);
  }
  if (displaySundays !== "true") {
    hiddenDays.push(0);
  }
  return hiddenDays;
};

const defaultFullCalendarConfig = () => ({
  locale: frLocale,
  allDaySlot: false,
  height: "auto",
  selectable: true,
  nowIndicator: true,
  businessHours: {
    // days of week. an array of zero-based day of week integers (0=Sunday)
    daysOfWeek: [1, 2, 3, 4, 5, 6, 0],
      startTime: '07:00',
      endTime: '20:00',
  },
  slotMinTime: '07:00:00',
  slotMaxTime: '20:00:00',
  selectAllow: canSelectOnlyOneDay,
  eventClassNames: eventClassNames,
  eventMouseLeave: (info) => $(info.el).tooltip('hide'), // extra security

  // Avec la valeur par défaut (15), les RDVs de 10 minutes sont affichés côte-à-côte, car :
  //   1. FullCalendar estime que c'est plus lisible de "gonfler" un peu l'affichage d'un événement très court (augmenter sa hauteur).
  //   2. FullCalendar affiche côte-à-côte des événements qui se chevauchent.
  //   3. Les événements de 10 minutes se chevauchent une fois gonflés.
  // Nous disons donc ici à FullCalendar de ne pas gonfler les événements courts, afin qu'ils
  // soient affichés les uns en dessous des autres, pour une meilleure lisibilité.
  // Nous gardons malgré tout une hauteur minimale de 8px car c'est la limite à laquelle on ne voit même plus le texte.
  eventMinHeight: 8,

  // This is a hack to make sure that the events will be shown at the proper time in the calendar.
  // If this is removed, there is a bug that causes the events in the calendar to be show at the wrong
  // time for agents that are not in the Paris timezone.
  // The proper fix for this would be to make sure we store all rdvs with the right timezone, but that's a much bigger project.
  // The timezone is forced to paris on the server side, so if we make sure that we also force it to the same timezone here,
  // we always have a consistent result.
  // We're always assuming that people are interested in their local time.
  //
  // There is one case for which this fix would fail: if the local time of the user and the agent is not the same (for example the agent is
  // in the métropole and the user is at la réunion), they will not see the same time
  // for the rdv. This seems unlikely for now.
  timeZone: "Europe/Paris",
});

function eventClassNames(info) {
  let extendedProps = info.event.extendedProps;
  const customCssClasses = [];

  // La nomenclature visuelle pour l'affichage des RDVs selon le statut est la suivante :
  // - RDV à renseigner / futur (unknown)   -> aucun effet
  // - RDV honoré (seen)                    -> transparent
  // - RDV non excusé, aka lapin (noshow)   -> barré
  // - RDV annulé par l'usager (excused)    -> transparent + barré
  // - RDV annulé par le service (revoked)  -> transparent + barré
  if(extendedProps.status === "seen") {
    customCssClasses.push("rdv-fc-event-transparent");
  }
  else if (extendedProps.status === "noshow") {
    customCssClasses.push("rdv-fc-event-barre");
  }
  else if (extendedProps.status === "excused" || extendedProps.status === "revoked") {
    customCssClasses.push("rdv-fc-event-transparent");
    customCssClasses.push("rdv-fc-event-barre");
  }

  if (extendedProps.unauthorizedRdvExplanation) {
    customCssClasses.push("rdv-fc-unauthorized-rdv");
  }

  if (extendedProps.userInWaitingRoom == true) {
    customCssClasses.push("rdv-fc-event-waiting");
  }

  return customCssClasses;
}

function eventRenderer(selectedEventId) {
  // On renvoie une fonction qui aura le bon selectedEventId
  return (info) => {
    let $el = $(info.el);
    let extendedProps = info.event.extendedProps;

    if (selectedEventId && info.event.id == selectedEventId) {
      $el.addClass("rdv-shake");
    }

    if (extendedProps.jour_feries == true) {
      return
    }

    const start = Intl.DateTimeFormat("fr", { timeZone: 'UTC', hour: 'numeric', minute: 'numeric' }).format(info.event.start);
    const end = Intl.DateTimeFormat("fr", { timeZone: 'UTC', hour: 'numeric', minute: 'numeric' }).format(info.event.end);

    let title = ``;

    if (info.isStart && info.isEnd) {
      title += `${start} - ${end}`;
    } else if (info.isStart) {
      title += `À partir de ${start}`;
    } else if (info.isEnd) {
      title += `Jusqu'à ${end}`;
    } else {
      title += `Toute la journée`;
    }

    if (info.event.display == 'background') {
      if (extendedProps.organisationName) {
        title += `<br>${extendedProps.organisationName}`;
      }
      title += `<br><strong>${info.event.title}</strong>`;
      if (extendedProps.lieu) {
        title += `<br> <small>Lieu : ${extendedProps.lieu}</small>`;
      }
    } else {
      if (extendedProps.duration) {
        title += ` <small>(${extendedProps.duration} min)</small>`;
        title += ` <br>${extendedProps.motif}`;
      }

      title += `<br><strong>${info.event.title}</strong>`;

      if (extendedProps.organisationName) {
        title += `<br>${extendedProps.organisationName}`;
      }
      if (extendedProps.lieu) {
        title += `<br><strong>Lieu:</strong> ${extendedProps.lieu}`;
      }
      if (extendedProps.readableStatus) {
        title += `<br><strong>Statut:</strong> ${extendedProps.readableStatus}`;
      }
      if (extendedProps.unauthorizedRdvExplanation) {
        title += `<br>${extendedProps.unauthorizedRdvExplanation}`;
      }
    }

    $el.attr("title", title);
    $el.attr("data-toggle", "tooltip");
    $el.attr("data-html", "true");
    $el.tooltip()
  }
}

const setupPollingRefresh = (fullCalendarInstance) => {
  const clearRefetchInterval = () => {
    if (!fullCalendarInstance.refreshCalendarInterval) return
    clearTimeout(fullCalendarInstance.refreshCalendarInterval)
    fullCalendarInstance.refreshCalendarInterval = null
  }

  const setRefetchInterval = () => {
    if (fullCalendarInstance.refreshCalendarInterval) return
    fullCalendarInstance.refreshCalendarInterval = setInterval(() => fullCalendarInstance.refetchEvents(), 30000)
  }

  setRefetchInterval();

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      // when agent comes back to tab, refresh immediately
      fullCalendarInstance.refetchEvents();

      setRefetchInterval();
    } else if (fullCalendarInstance.refreshCalendarInterval) {
      clearRefetchInterval();
    }
  })
};

const setupRealtimeRefresh = (fullCalendarInstance, agentIds) => {

  const messageReceivedCallback = (message) => {
    if (Array.isArray(message.refresh_periods) && message.refresh_periods.length > 0) {
      const beginningOfView = fullCalendarInstance.view.activeStart.toISOString();
      const endOfView = fullCalendarInstance.view.activeEnd.toISOString();
      const intersectsFunction = ([periodStart, periodEnd]) => (periodEnd > beginningOfView && periodStart < endOfView);
      if (message.refresh_periods.some(intersectsFunction)) {
        fullCalendarInstance.refetchEvents();
      }
    } else {
      fullCalendarInstance.refetchEvents();
    }
  };

  const connectCallback = ({ reconnected }) => {
    // `reconnected` est à `false` uniquement lors de la connexion initiale.
    if (reconnected) {
      fullCalendarInstance.refetchEvents();
    }
  };

  agentIds.forEach(agentId => {
    getConsumer().subscriptions.create({channel: "AgendaChannel", agent_id: agentId}, {
      received: messageReceivedCallback,
      connected: connectCallback,
    });
  });

  const refreshDisconnectedWarning = () => {
    const alertElement = document.querySelector("#js-agenda-disconnected-warning");
    const connexionIsStale = getConsumer().connection.monitor.connectionIsStale();
    alertElement.hidden = !connexionIsStale;
  };
  setInterval(refreshDisconnectedWarning, 500);
};

const handleAjaxError = (response) => {
  if (window.ajaxErrorHandledAt) {
    const secondsSinceLast = (Date.now() - window.ajaxErrorHandledAt) / 1000;
    if (secondsSinceLast < 60) return
  }
  window.ajaxErrorHandledAt = Date.now()

  switch (response.xhr.status) {
    case 401:
      window.location = this.calendarEl.attributes["data-sign-in-path"].value;
      break;
    case 500:
      alert(`Le chargement du calendrier a échoué; un rapport d’erreur a été transmis à l’équipe.\nRechargez la page, et si ce problème persiste, contactez-nous à support@rdv-service-public.fr`);
      break;
    case 0:
      alert(`Le chargement du calendrier a échoué, probablement car votre connexion internet a été coupée.\nRechargez la page, et si ce problème persiste, contactez-nous à support@rdv-service-public.fr`);
      break;
    default:
      alert(`Le chargement du calendrier a échoué avec une erreur ${response.xhr.status}\nRechargez la page, et si ce problème persiste, contactez-nous à support@rdv-service-public.fr`)
  }
};

export { defaultFullCalendarConfig, eventRenderer, setupPollingRefresh, setupRealtimeRefresh, handleAjaxError }
