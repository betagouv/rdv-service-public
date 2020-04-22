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
  var calendarEl = document.getElementById('calendar');

  let defaultView = "timeGridOneDay";
  if (!browser.is("mobile")) {
    let viewFromLocalStorage = localStorage.getItem("calendarDefaultView");

    defaultView = ['dayGridMonth', 'timeGridWeek', 'timeGridOneDay'].includes(viewFromLocalStorage) ? viewFromLocalStorage : "timeGridWeek";
  }

  if (calendarEl !== null ) {
    var calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      locale: frLocale,
      eventSources: JSON.parse(calendarEl.dataset.eventSources),
      eventSourceFailure: function (errorObj) {
        alert("Une erreur s'est produite lors de la récupération des données du calendrier.");
      },
      defaultDate: JSON.parse(calendarEl.dataset.defaultDate),
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
          organisation_id: calendarEl.dataset.organisationId,
          "agent_ids[]": calendarEl.dataset.agentId,
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
        if ($('#fc-date').length) {
          $('#fc-date').val(moment(info.view.activeStart).format('L'))
        }
      },
      eventRender: function (info) {
        let $el = $(info.el);

        if(info.event.extendedProps.past == true) {
          $el.addClass("fc-event-past");
        };
        if(info.event.extendedProps.duration <= 30) {
          $el.addClass("fc-event-small");
        };
        $el.addClass("fc-event-"+ info.event.extendedProps.status);
        if (info.event.extendedProps.unclickable != true){
          $el.attr("data-rightbar", "true");
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

    setInterval(function(){ calendar.refetchEvents }, 30000)
  }
});
