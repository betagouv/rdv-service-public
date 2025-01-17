import 'bootstrap';

import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import { defaultFullCalendarConfig, eventRenderer } from  './calendar/utils'

class RdvPlanCalendar {

  constructor() {
    const calendarEl = document.getElementById('rdvPlanCalendar');
    if (calendarEl == null || calendarEl.innerHTML !== "")
      return

    return new Calendar(calendarEl, this.calendarConfig(calendarEl.dataset)).render();
  }

  calendarConfig = (dataset) => {
    const options = {
      plugins: [timeGridPlugin, interactionPlugin],
      eventSources: JSON.parse(dataset.eventSourcesJson),
      defaultDate: JSON.parse(dataset.defaultDateJson),
      defaultView: dataset.singleDay === "true" ? 'timeGridDay' : 'timeGridWeek',
      hiddenDays: [],
      header: { left:  '', center: '', right:  '' },
      select: this.selectEvent,
      minTime: dataset.minTime || '07:00:00',
      maxTime: dataset.maxTime || '20:00:00',
      eventRender: eventRenderer(),
    }

    if (dataset.displaySaturdays !== "true") {
      options.hiddenDays.push(6);
    }
    if (dataset.singleDay !== "true") {
      options.header.right = 'prev,next';
    }

    return { ...defaultFullCalendarConfig(), ...options };
  }

  selectEvent = (info) => {
    const field = document.getElementById('rdvPlanCalendarField')
    field.value = info.startStr
    const form = document.getElementById('rdvPlanCalendarForm')
    form.submit()
  }
}

document.addEventListener('turbolinks:load', function () {
  new RdvPlanCalendar()
});
