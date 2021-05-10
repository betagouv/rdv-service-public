class ShowSmsProviderConfigurationForm {
  constructor() {
    // have to use jQuery here because of select2
    //$(".js-merge-users-user-select").on("change", this.userSelected)
    $("#territory_sms_provider").on("change", this.providerSelect)
    $(`.js-${$("#territory_sms_provider").val()}`).removeClass("d-none")
  }

  providerSelect = (event) => {
    $(`.js-sms-configuration-form`).addClass("d-none")
    $(`.js-${event.currentTarget.value}`).removeClass("d-none")
  }

}

export { ShowSmsProviderConfigurationForm }

