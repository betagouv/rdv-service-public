import { Calendar } from "@fullcalendar/core";
import resourceTimegridPlugin from "@fullcalendar/resource-timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import { defaultFullCalendarConfig, eventRenderer, setupRefresh, handleAjaxError } from "./utils";

class AgendaMultiAgent {
  constructor() {
    this.calendarEl = document.querySelector("#agenda-multi-agent");
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "") {
      return;
    }

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
    setupRefresh(this.fullCalendarInstance);
  }
  initFullCalendar = () => {
    const hiddenDays = []
    if (this.data.displaySaturdays !== "true") {
      hiddenDays.push(6);
    }
    if (this.data.displaySundays !== "true") {
      hiddenDays.push(0);
    }
    const options = {
      plugins: [resourceTimegridPlugin, interactionPlugin],
      schedulerLicenseKey: "GPL-My-Project-Is-Open-Source",
      resources: JSON.parse(this.data.resourcesJson),
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: handleAjaxError,
      initialView: localStorage.getItem("chosenCalendarView") || "resourceTimeGridWeek",
      initialDate: localStorage.getItem("chosenCalendarDay"),
      headerToolbar: {
        center: "resourceTimeGridDay,resourceTimeGridWeek"
      },
      customButtons: this.customButtons(),
      footerToolbar: {
        end: "toggleGrouping"
      },
      datesAboveResources: this.getGroupByDate(),
      datesSet: this.datesSet,
      hiddenDays: hiddenDays,
      select: this.selectEvent,
      eventDidMount: eventRenderer(),
      views: {

        resourceTimeGridDay: {
          buttonText: "jour",
          titleFormat: { weekday: "long", day: "numeric", month: "long", year: "numeric" }
        },

        resourceTimeGridWeek: {
          type: "resourceTimeGrid",
          duration: { week: 1 },
          buttonText: "semaine",
          titleFormat: { weekday: "long", day: "numeric", month: "short", year: "numeric" }
        },

      },
    };
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
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

  toggleGrouping = () => {
    localStorage.setItem("groupByDate", this.getGroupByDate() ? "false" : "true");
    this.fullCalendarInstance.setOption("datesAboveResources", this.getGroupByDate());
    this.fullCalendarInstance.setOption("customButtons", this.customButtons());
    this.refreshColumnsVisualGrouping();
  }

  refreshColumnsVisualGrouping = () => {
    const white = "#FFF";
    const grey = "rgb(227, 234, 239, 0.5)";
    const groupedByDate = this.getGroupByDate();

    const columns = document.querySelectorAll(".fc-timegrid-col.fc-day");
    const columnGroups = Object.groupBy(columns, column => groupedByDate ? column.dataset.date : column.dataset.resourceId);
    Object.entries(columnGroups).forEach((group, index) => {
      group[1].forEach(columnElement => {
        columnElement.style.backgroundColor = (index & 1) ? white : grey;
      });
    })
  }

  getGroupByDate = () => {
    return localStorage.getItem("groupByDate") !== "false";
  }

  customButtons = () => {
    return {
      toggleGrouping: {
        text: this.getGroupByDate() ? "Grouper par agent" : "Grouper par date",
        click: this.toggleGrouping,
      }
    }
  }
}

export { AgendaMultiAgent }
