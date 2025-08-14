import 'bootstrap';

import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import { defaultFullCalendarConfig, eventRenderer } from  './calendar/utils'

export class RdvPlanCalendar {

  constructor() {
    const calendarEl = document.getElementById('rdvPlanCalendar');
    if (calendarEl == null || calendarEl.innerHTML !== "")
      return

    let calendar = new Calendar(calendarEl, this.calendarConfig(calendarEl.dataset))
    calendar.render();

    return calendar;
  }

  calendarConfig = (dataset) => {
    const options = {
      plugins: [timeGridPlugin, interactionPlugin],
      eventSources: JSON.parse(dataset.eventSourcesJson),
      initialDate: JSON.parse(dataset.defaultDateJson),
      initialView: dataset.singleDay === "true" ? 'timeGridDay' : 'timeGridWeek',
      hiddenDays: [0],
      headerToolbar: { left:  '', center: '', right:  '' },
      select: this.selectEvent,
      slotMinTime: dataset.slotMinTime || '07:00:00',
      slotMaxTime: dataset.slotMaxTime || '20:00:00',
      eventDidMount: eventRenderer(),
    }

    if (dataset.displaySaturdays !== "true") {
      options.hiddenDays.push(6);
    }
    if (dataset.singleDay !== "true") {
      options.headerToolbar.right = 'prev,next';
    }

    return { ...defaultFullCalendarConfig(), ...options };
  }

  selectEvent = (info) => {
    document.getElementById('rdvPlanCalendarField').value = info.startStr
    document.getElementById('rdvPlanCalendarForm').submit()
  }
}