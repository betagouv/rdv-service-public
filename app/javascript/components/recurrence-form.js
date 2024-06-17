class RecurrenceForm {
  constructor() {
    this.element = document.querySelector('.js-recurrence-container')
    if (!this.element) return;

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

    $(this.repetitionEndingMode).on("change", () => { this.toggleRepetitionEndingInput() })
    $(this.everyTarget).on("change", () => { this.toggleFrequence(); } )
  }

  toggleRepetitionEndingInput = () => {
    const repetitionEndingInputs = { "none": [], "date": this.untilDateInput, "occurences": this.untilOccurencesCountInput }
    const inputToShow = $(repetitionEndingInputs[this.repetitionEndingMode.value])
    const inputToHide = $(".js-repetition-ending-input").not(inputToShow)
    $(inputToHide).hide();
    $(inputToShow).show();
  }

  toggleFrequence = () => {
    this.element.classList.remove("recurrence-select--weekly", "recurrence-select--monthly", "recurrence-select--never");

    switch(this.everyTarget.value) {
      case "week":
        this.element.classList.add("recurrence-select--weekly");
        break
      case "month":
        this.element.classList.add("recurrence-select--monthly");
        break;
      default:
        this.element.classList.add("recurrence-select--never");
    }
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
