class RecurrenceForm {
  constructor() {
    this.element = document.querySelector('.js-recurrence-container')
    if (!this.element) return;

    this.hasRecurrenceTarget = document.querySelector('.js-recurrence-toggle')
    this.recurrenceComputedTarget = document.querySelector('.js-recurrence-computed')
    this.intervalTarget = document.querySelector('.js-recurrence-interval')
    this.everyTarget = document.querySelector('.js-recurrence-every')
    this.onTargets = Array.from(document.querySelectorAll('.js-recurrence-on'))
    this.untilTarget = document.querySelector('.js-recurrence-until')
    this.firstDayTarget = document.querySelector('.js-recurrence-first-day')
    this.monthlyTarget = document.querySelector('.js-recurrence-monthly')

    document.querySelectorAll('.js-recurrence-input').
      forEach(i => i.addEventListener('change', this.updateRecurrence))

    let model = this.getRecurrenceComputed() || {};
    if (model.every == undefined) {
      this.hasRecurrenceTarget.checked = false;
    } else {
      this.hasRecurrenceTarget.checked = true;
      this.everyTarget.value = model.every;
      this.intervalTarget.value = model.interval;
      if (model.until) {
        this.untilTarget.value = moment(model.until).format("DD/MM/YYYY");
      }
    }
    if(model.every == "week") this.setOn(model);
    this.updateView(model);
  }

  setOn = (model) => {
    this.onTargets.forEach(elt => elt.checked = (typeof(model.on) == "object") && model.on.includes(elt.value));
  }

  getOn = () => {
    return this.onTargets.filter(x => x.checked).map(x => x.value);
  }

  getFirstDay = () => {
    return moment(this.firstDayTarget.value, "DD/MM/YYYY");
  }

  setRecurrenceComputed = (model) => {
    if (model.every == undefined) {
      this.recurrenceComputedTarget.value = "";
    } else {
      this.recurrenceComputedTarget.value = JSON.stringify(model);
    }
  }

  getRecurrenceComputed = () => {
    if (this.recurrenceComputedTarget.value === "")
      return null
    return JSON.parse(this.recurrenceComputedTarget.value);
  }

  updateRecurrence = () => {
    let model = {};

    if (this.hasRecurrenceTarget.checked) {
      model.every = this.everyTarget.value;
      model.interval = Number(this.intervalTarget.value);
      model.starts = this.firstDayTarget.value;

      if (model.every == "week") {
        let on = this.getOn();
        if (on.length > 0) {
          model.on = on;
        }
      } else if (model.every == "month") {
        model.day = {};
        model.day[this.getWeekday(this.getFirstDay())] = this.getWeekdayPositionInMonth(this.getFirstDay());
      }

      if (this.untilTarget.value) model.until = this.untilTarget.value;
    }

    this.updateView(model)
    this.setRecurrenceComputed(model);
  }

  updateView = (model) => {
    this.element.classList.remove("recurrence-select--weekly");
    this.element.classList.remove("recurrence-select--monthly");
    this.element.classList.remove("recurrence-select--never");

    if (model.every == "week") {
      this.element.classList.add("recurrence-select--weekly");
    } else if (model.every == "month") {
      this.monthlyTarget.innerHTML = this.getDayText(this.getFirstDay());
      this.element.classList.add("recurrence-select--monthly");
    } else {
      this.element.classList.add("recurrence-select--never");
    }
  }

  getWeekday = (momentDate) => {
    return momentDate.locale("en").format("dddd").toLowerCase();
  }

  getWeekdayPositionInMonth = (momentDate) => {
    let dayInMonth = momentDate.date();
    return Math.floor((dayInMonth - 1) / 7) + 1;
  }

  getDayText = (momentDate) => {
    let nthWeekdayOfMonth = this.getWeekdayPositionInMonth(momentDate)
    if (nthWeekdayOfMonth == 1) {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}er`
    } else {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}ème`
    }

    return `Tous les ${nthWeekdayOfMonth} ${momentDate.format("dddd")} du mois`;
  }
}

export { RecurrenceForm }
