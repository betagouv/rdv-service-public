import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import frLocale from '@fullcalendar/core/locales/fr';
import interactionPlugin from '@fullcalendar/interaction';
import Routes from '../../routes.js.erb';

document.addEventListener('turbolinks:load', function() {
  var calendarEl = document.getElementById('calendar');

  if (calendarEl !== null ) {
    var calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      locale: frLocale,
      eventSources: ['/rdvs', '/absences', '/plage_ouvertures'],
      defaultView: 'timeGridFourDay',
      selectable: true,
      select: function(info) {
        let startDate = moment(info.start);
        let params = { starts_at: info.startStr };
        let plage_ouvertures = calendar.getEvents()
          .filter(e => e.rendering == "background")
          .filter(e => startDate.isBetween(e.start, e.end, null, "[]"));

        if (plage_ouvertures[0] !== undefined) {
          params.location = plage_ouvertures[0].extendedProps.location;
        }
        window.location = Routes.new_first_step_path(params);
      },
      header: {
         center: 'dayGridMonth,timeGridWeek,timeGridFourDay'
      },
      views: {
        timeGridFourDay: {
          type: 'timeGrid',
          duration: { days: 4 },
          buttonText: '4 jours',
          slotDuration: '00:15:00'
        }
      },
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: '06:00:00',
      maxTime: '20:00:00',
      eventRender: function (info) {
        if(info.event.extendedProps.past == true) {
          $(info.el).addClass("fc-event-past");
        };
        $(info.el).addClass("fc-event-"+ info.event.extendedProps.status);
        $(info.el).attr("data-rightbar", "true");
      }
    });

    calendar.render();
  }
});
