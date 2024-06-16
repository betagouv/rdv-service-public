class RecurrenceForm {
  constructor() {
    this.element = document.querySelector('.js-recurrence-container')
    if (!this.element) return;

    this.hasRecurrenceTarget = document.querySelector('.js-recurrence-toggle')
    this.recurrenceComputedTarget = document.querySelector('.js-recurrence-computed')
    this.intervalTarget = document.querySelector('.js-recurrence-interval')
    this.everyTarget = document.querySelector('.js-recurrence-every')
    this.onTargets = Array.from(document.querySelectorAll('.js-recurrence-on'))
    this.untilDateTarget = document.querySelector('.js-recurrence-until-date')
    this.untilOccurencesCountTarget = document.querySelector('.js-recurrence-until-occurences-count')
    this.repetitionEndingMode = document.querySelector('.js-recurrence-repetition-ending-mode')
    this.firstDayTarget = document.querySelector('.js-recurrence-first-day')
    this.monthlyTarget = document.querySelector('.js-recurrence-monthly')
    this.untilDateInput = document.querySelector('.js-until-date')
    this.untilOccurencesCountInput = document.querySelector('.js-until-occurences-count')

    $(this.repetitionEndingMode).on('change', () => { this.toggleUntilInput() })

    document.querySelectorAll('.js-recurrence-input').
      forEach(i => i.addEventListener('change', this.updateRecurrence))

    let model = this.getRecurrenceComputed() || {};
    if (model.every == undefined) {
      this.hasRecurrenceTarget.checked = false;
    } else {
      this.hasRecurrenceTarget.checked = true;
      this.everyTarget.value = model.every;
      this.intervalTarget.value = model.interval;
    }
    if(model.every == "week") this.setOn(model);
    if(model.until) this.untilDateTarget.value = Intl.DateTimeFormat("fr").format(new Date(model.until))
    if(model.total) this.untilOccurencesCountTarget.value = parseInt(model.total)
    this.updateView(model);
  }

  setOn = (model) => {
    this.onTargets.forEach(elt => elt.checked = (typeof(model.on) == "object") && model.on.includes(elt.value));
  }

  getOn = () => {
    return this.onTargets.filter(x => x.checked).map(x => x.value);
  }

  getFirstDay = () => {
    const datePattern = /^(\d{2})\/(\d{2})\/(\d{4})$/;
    const [, day, month, year] = datePattern.exec(this.firstDayTarget.value)
    return new Date(`${year}-${month}-${day}`);
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
      model.starts = this.firstDayTarget.value

      if (model.every == "week") {
        let on = this.getOn();
        if (on.length > 0) {
          model.on = on;
        }
      } else if (model.every == "month") {
        model.day = {};
        model.day[this.getWeekday(this.getFirstDay())] = this.getWeekdayPositionInMonth(this.getFirstDay().getDate());
      }

      switch (this.repetitionEndingMode.value) {
        case "never":
          model.until = null
          model.total = null
          break;
        case "until_date":
          model.until = this.untilDateTarget.value;
          model.total = null;
          break;
        case "until_occurences_count":
          model.total = parseInt(this.untilOccurencesCountTarget.value);
          model.until = null;
          break;
        default:
          model.until = null;
          model.total = null;
      }
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

    if (model.until) {
      this.repetitionEndingMode.value = "date"
    } else if (model.total) {
      this.repetitionEndingMode.value = "occurrences"
    }
    this.toggleUntilInput();
  }

  getWeekday = (date) => {
    // On force EN ici parce que Montrose vérifie avec les noms anglais des jours de semaine
    return Intl.DateTimeFormat("en", {weekday: "long"}).format(date).toLowerCase();
  }

  getWeekdayPositionInMonth = (dayInMonth) => {
    return Math.floor((dayInMonth - 1) / 7) + 1;
  }

  getDayText = (date) => {
    let nthWeekdayOfMonth = this.getWeekdayPositionInMonth(date.getDate())
    if (nthWeekdayOfMonth == 1) {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}er`
    } else {
      nthWeekdayOfMonth = `${nthWeekdayOfMonth}ème`
    }

    // On force en françois puisque c'est affiché en français
    return `Tous les ${nthWeekdayOfMonth} ${Intl.DateTimeFormat("fr", {weekday: "long"}).format(date).toLowerCase()} du mois`;
  }

  toggleUntilInput = () => {
    const fields = { "none": [], "date": this.untilDateInput, "occurences": this.untilOccurencesCountInput }
    const toDisplay = $(fields[this.repetitionEndingMode.value])
    const toHide = $(".js-repetition-ending-input").not(toDisplay)
    $(toDisplay).show();
    $(toHide).hide();
  }
}

export { RecurrenceForm }
