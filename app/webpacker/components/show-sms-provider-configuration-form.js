class ShowSmsProviderConfigurationForm {
  constructor() {
    $("#territory_sms_provider").on("change", this.providerSelect)
    $(`.js-${$("#territory_sms_provider").val()}`).removeClass("d-none")
  }

  providerSelect = (event) => {
    $(`.js-sms-configuration-form`).addClass("d-none")
    $(`.js-${event.currentTarget.value}`).removeClass("d-none")
  }

}

export { ShowSmsProviderConfigurationForm }

