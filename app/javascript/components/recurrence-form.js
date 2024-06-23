class RecurrenceForm {
  constructor() {
    this.element = document.querySelector('.js-recurrence-container')
    if (!this.element) return;

    this.everyTarget = document.querySelector('.js-recurrence-every')
    this.repetitionEndingMode = document.querySelector('.js-recurrence-repetition-ending-mode')
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
