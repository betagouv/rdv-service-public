import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import frLocale from '@fullcalendar/core/locales/fr';

document.addEventListener('turbolinks:load', function() {
  var calendarEl = document.getElementById('calendar');

  if (calendarEl !== null ) {
    var calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin],
      locale: frLocale,
      events: window.events,
      defaultView: 'timeGridWeek',
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: '06:00:00',
      maxTime: '20:00:00',
    });

    calendar.render();
  }
});
