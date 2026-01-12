import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import {
  defaultFullCalendarConfig,
  hiddenDays,
} from './calendar/utils'

export class AgendaPlageOuverture {
  constructor() {
    this.calendarEl = document.getElementById('agenda_plages');
    if (!this.calendarEl) {
      return;
    }

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
  }

  initFullCalendar = () => {
    const options = {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      eventSources: JSON.parse(this.data.eventSourcesJson),
      hiddenDays: hiddenDays(this.data),
      select: this.selectEvent,
      initialView: "timeGridWeek",
      headerToolbar: { left: "today,prev,next,title", center: "dayGridMonth,timeGridWeek", right: "" },
    }
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
  }

  selectEvent = (info) => {
    const urlSearchParams = new URLSearchParams({
      first_day: info.startStr.slice(0, 10),
      start_time: info.startStr.slice(11, 16),
      end_time: info.endStr.slice(11, 16),
      agent_id: this.data.agentId,
    });
    window.location = `/admin/organisations/${this.data.organisationId}/planning/plage_ouvertures/new?${urlSearchParams.toString()}`;
  }
}
