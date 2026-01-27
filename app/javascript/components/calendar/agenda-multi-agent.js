import { Calendar } from "@fullcalendar/core";
import resourceTimegridPlugin from "@fullcalendar/resource-timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import {
  defaultFullCalendarConfig,
  eventRenderer,
  setupRealtimeRefresh,
  handleAjaxError,
  dayHeaderContent,
  betaWeekTitleFormat,
  preferencesModalToggle,
  hiddenDays,
} from "./utils";

class AgendaMultiAgent {
  constructor() {
    this.calendarEl = document.querySelector("#agenda-multi-agent");
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "") {
      return;
    }

    this.data = this.calendarEl.dataset
    this.resources = JSON.parse(this.data.resourcesJson);
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
    setupRealtimeRefresh(this.fullCalendarInstance, this.resources.map(resource => resource.id));
  }
  initFullCalendar = () => {
    const options = {
      plugins: [resourceTimegridPlugin, interactionPlugin],
      schedulerLicenseKey: "GPL-My-Project-Is-Open-Source",
      resources: this.resources,
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: handleAjaxError,
      initialView: this.getInitialView(),
      initialDate: localStorage.getItem("chosenCalendarDay"),
      headerToolbar: {
        left: "today,prev,next,title",
        center: "resourceTimeGridDay,resourceTimeGridWeek",
        right: "preferencesModalToggle",
      },
      titleFormat: betaWeekTitleFormat,
      dayHeaderContent: dayHeaderContent,
      customButtons: { preferencesModalToggle },
      datesAboveResources: this.data.groupByAgent !== "true",
      datesSet: this.datesSet,
      hiddenDays: hiddenDays(this.data),
      select: this.selectEvent,
      eventDidMount: eventRenderer(),
      views: this.views(),
    };
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
  }

  getInitialView = () => {
    const storedValue = localStorage.getItem("chosenCalendarView");
    if (Object.keys(this.views()).includes(storedValue)) {
      return storedValue;
    } else {
      return "resourceTimeGridWeek"
    }
  }

  views = () => {
    return {
      resourceTimeGridDay: {
        buttonText: "Journée",
        titleFormat: {weekday: "long", day: "numeric", month: "long", year: "numeric"},
      },
      resourceTimeGridWeek: {
        type: "resourceTimeGrid",
        duration: {week: 1},
        buttonText: "Semaine",
      },
    }
  }

  selectEvent = (info) => {
    const urlSearchParams = new URLSearchParams({
      starts_at: info.startStr,
      "agent_ids[]": info.resource.id,
    });
    window.location = `/admin/organisations/${this.data.organisationId}/rdv_wizard_step/new?${urlSearchParams.toString()}`;
  }
 
  datesSet = (info) => {
    localStorage.setItem("chosenCalendarView", info.view.type);
    localStorage.setItem("chosenCalendarDay", info.startStr?.split("T")[0]);
    this.refreshColumnsVisualGrouping();
  }

  refreshColumnsVisualGrouping = () => {
    const allColumns = document.querySelectorAll(".fc-timegrid-col.fc-day");
    const WHITE = "#FFF";
    const GREY = "#f3f6fe";

    if (this.fullCalendarInstance.view.type !== "resourceTimeGridWeek") {
      return allColumns.forEach(column => column.style.backgroundColor = WHITE); // Reset to white
    }

    const groupingCriteria = (column) => (this.data.groupByAgent === "true" ? column.dataset.resourceId : column.dataset.date);
    Object.values(Object.groupBy(allColumns, groupingCriteria))
      .forEach((columnGroup, i) =>
        columnGroup.forEach(column => column.style.backgroundColor = i % 2 ? WHITE : GREY)
      );
  };
}

export { AgendaMultiAgent }
