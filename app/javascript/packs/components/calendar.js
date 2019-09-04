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
      eventSources: ['/events', '/background-events'],
      defaultView: 'timeGridFourDay',
      selectable: true,
      select: function(info) {
        window.location = Routes.new_first_step_path({ start_at: info.startStr });
      },
      header: {
         center: 'dayGridMonth,timeGridWeek,timeGridFourDay'
      },
      views: {
        timeGridFourDay: {
          type: 'timeGrid',
          duration: { days: 4 },
          buttonText: '4 jours'
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
        if(info.event.extendedProps.cancelled == true) {
          $(info.el).addClass("fc-event-cancelled");
        };
        $(info.el).addClass("fc-event-"+ info.event.extendedProps.status);
        $(info.el).attr("data-rightbar", "true");
      }
    });

    calendar.render();
  }
});
