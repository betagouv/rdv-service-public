import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import frLocale from '@fullcalendar/core/locales/fr';
import interactionPlugin from '@fullcalendar/interaction';
import Routes from '../routes.js.erb';
import Bowser from "bowser";
const browser = Bowser.getParser(window.navigator.userAgent);

document.addEventListener('turbolinks:load', function() {
  const calendarEl = document.getElementById('calendar');

  let defaultView = "timeGridOneDay";
  if (!browser.is("mobile")) {
    let viewFromLocalStorage = localStorage.getItem("calendarDefaultView");

    defaultView = ['dayGridMonth', 'timeGridWeek', 'timeGridOneDay'].includes(viewFromLocalStorage) ? viewFromLocalStorage : "timeGridWeek";
  }

  if (calendarEl !== null && calendarEl.innerHTML == "") {
    const { eventSourcesJson, defaultDateJson, selectedEventId, organisationId, agentId } = calendarEl.dataset
    const defaultDate = JSON.parse(defaultDateJson || sessionStorage.getItem('calendarStartDate'))
    var calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      locale: frLocale,
      eventSources: JSON.parse(eventSourcesJson),
      eventSourceFailure: function (errorObj) {
        alert("Une erreur s'est produite lors de la récupération des données du calendrier.");
      },
      defaultDate: defaultDate,
      defaultView: defaultView,
      viewSkeletonRender: function (info) {
        localStorage.setItem("calendarDefaultView", info.view.type);
      },
      weekends: false,
      height: "auto",
      selectable: true,
      select: function(info) {
        if ($('body').hasClass('right-bar-enabled')) return false;

        let startDate = moment(info.start);
        let params = {
          starts_at: info.startStr,
          organisation_id: organisationId,
          "agent_ids[]": agentId,
         };
        let plage_ouvertures = calendar.getEvents()
          .filter(e => e.rendering == "background")
          .filter(e => startDate.isBetween(e.start, e.end, null, "[]"));

        if (plage_ouvertures[0] !== undefined) {
          params['plage_ouverture_location'] = plage_ouvertures[0].extendedProps.location;
        }
        window.location = Routes.new_organisation_rdv_wizard_step_path(params);

      },
      header: {
        center: 'dayGridMonth,timeGridWeek,timeGridOneDay'
      },
      views: {
        timeGridOneDay: {
          type: 'timeGrid',
          duration: { days: 1 },
          buttonText: 'Journée'
        }
      },
      timeGridEventMinHeight: 5,
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: '07:00:00',
      maxTime: '20:00:00',
      datesRender: function(info) {
        sessionStorage.setItem("calendarStartDate", JSON.stringify(info.view.currentStart))
        const printLinkElt = document.querySelector(".js-link-print-rdvs")
        printLinkElt.classList.toggle("d-none", info.view.type != "timeGridOneDay")
        if (info.view.type != "timeGridOneDay") return

        const url = new URL(printLinkElt.href)
        const date = moment(info.view.currentStart)
        printLinkElt.querySelector(".js-date").innerHTML = date.format("DD/MM/YYYY")
        url.searchParams.set("date", date.format("YYYY-MM-DD"))
        printLinkElt.href = url.toString()
      },
      eventRender: function (info) {
        let $el = $(info.el);
        if(info.event.extendedProps.past == true) {
          $el.addClass("fc-event-past");
        };
        if(info.event.extendedProps.duration <= 30) {
          $el.addClass("fc-event-small");
        };
        if (selectedEventId && info.event.id == selectedEventId) $el.addClass("selected");
        $el.addClass("fc-event-"+ info.event.extendedProps.status);
        if (info.event.extendedProps.unclickable != true){
          let title = `${moment(info.event.start).format('H:mm')} - ${moment(info.event.end).format('H:mm')}`;
          if (info.event.rendering == 'background') {
            $el.append("<div class=\"fc-title\" style=\"color: white; padding: 2px 4px; font-size: 12px; font-weight: bold;\">" + info.event.title + "</div>");

            title += `<br><strong>${info.event.title}</strong><br> <small>Lieu : ${info.event.extendedProps.lieu}</small>`;
          } else {
            if (info.event.extendedProps.duration) {
              title += ` <small>(${info.event.extendedProps.duration} min)</small>`;
              title += ` <br>${info.event.extendedProps.motif}`;
            }
            title += `<br><strong>${info.event.title}</strong>`;
            title += `<br><strong>Statut:</strong> ${info.event.extendedProps.readableStatus}`;
          }

          $el.attr("title", title);
          $el.attr("data-toggle", "tooltip");
          $el.attr("data-html", "true");
          $el.tooltip()
        }
      }
    });

    window.calendar = calendar
    calendar.render();

    setInterval(function(){ calendar.refetchEvents() }, 30000)
  }
});


document.addEventListener("turbolinks:before-cache", function() {
  const calendarElt = document.getElementById('calendar')
  if (!calendarElt) { return false }
  // force calendar reload on turbolinks re-visit, otherwise event listeners
  // are not attached
  calendarElt.innerHTML = ""
  // fixes hanging tooltip on back
  $(".tooltip").removeClass("show")
})
