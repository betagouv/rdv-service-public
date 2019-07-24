import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "hasRecurrence", "recurrenceComputed", "interval", "every", "on", "until", "firstDay", "monthly" ]

  setOn (model) {
    this.onTargets.forEach(elt => elt.checked = model.on.includes(elt.id));
  }

  getOn () {
    return this.onTargets.filter(x => x.checked).map(x => x.value);
  }

  getFirstDay () {
    return moment(this.firstDayTarget.value, "YYYY-MM-DD");
  }

  setRecurrenceComputed (model) {
    if (model.every == undefined) {
      this.recurrenceComputedTarget.value = "";
    } else {
      this.recurrenceComputedTarget.value = JSON.stringify(model);
    }
  }

  getRecurrenceComputed () {
    return JSON.parse(this.recurrenceComputedTarget.value);
  }

  initialize() {
    let model = this.getRecurrenceComputed() || {};

    if (model.every == undefined) {
      this.hasRecurrenceTarget.checked = false;
    } else {
      this.hasRecurrenceTarget.checked = true;
      this.everyTarget.value = model.every;
      this.intervalTarget.value = model.interval;
      if (model.until) {
        this.untilTarget.value = moment(model.until).format("YYYY-MM-DD");
      }
    }

    if(model.every == "week") {
      this.setOn(model);
    }

    this.updateView(model);
  }

  updateRecurrence () {
    let model = {};
    let firstDay;

    if (this.hasRecurrenceTarget.checked) {
      model.every = this.everyTarget.value;
      model.interval = Number(this.intervalTarget.value);

      if (model.every == "week") {
        let on = this.getOn();
        if (on.length > 0) {
          model.on = on;
        }
      } else if (model.every == "month") {
        // if (this.monthlyTarget.value == "mday") {
        //   model.mday = this.getFirstDay().date();
        // }
        if (this.monthlyTarget.value == "day") {
          model.day = {};
          model.day[this.getWeekday(this.getFirstDay())] = this.getWeekdayPositionInMonth(this.getFirstDay());
        }
      }

      if (this.untilTarget.value) {
        model.until = this.untilTarget.value;
      }
    }

    this.updateView(model)
    this.setRecurrenceComputed(model);
  }

  updateView (model) {
    this.element.classList.remove("recurrence-select--weekly");
    this.element.classList.remove("recurrence-select--monthly");
    this.element.classList.remove("recurrence-select--never");

    if (model.every == "week") {
      this.element.classList.add("recurrence-select--weekly");
    } else if (model.every == "month") {
      // this.monthlyTarget.querySelector("#mday").innerHTML = this.getMDayText(this.getFirstDay());
      this.monthlyTarget.querySelector("#day").innerHTML = this.getDayText(this.getFirstDay());
      this.element.classList.add("recurrence-select--monthly");
    } else {
      this.element.classList.add("recurrence-select--never");
    }
  }

  // getMDayText (momentDate) {
  //   return `Tous les mois le ${momentDate.format("D")}`;
  // }

  getWeekday (momentDate) {
    return momentDate.locale("en").format("dddd").toLowerCase();
  }

  getWeekdayPositionInMonth (momentDate) {
    let dayInMonth = momentDate.date();
    return Math.floor((dayInMonth - 1) / 7) + 1;
  }

  getDayText (momentDate) {
    let nthWeekdayOfMonth = this.getWeekdayPositionInMonth(momentDate)
    if (nthWeekdayOfMonth == 1) {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}er`
    } else {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}ème`
    }

    return `Tous les ${nthWeekdayOfMonth} ${momentDate.format("dddd")} du mois`;
  }
}
