// See also AgentsHelper::planning_agent_select
class ParticipationSelect {
  constructor() {
    this.$select = $(".js-rdv-user-select")
    if (!this.$select) return

    this.$select.on("change", this.userSelected)

    const userSelector = document.querySelector(".js-rdv-user-select")

    if (userSelector && userSelector.dataset.scrollToBottom === "true") {
      window.scrollTo(0,document.body.scrollHeight);
    }
  }

  userSelected = (event) => {
    let url = new URL(window.location.href);
    let user_id = this.$select.select2("data")[0].element.value;
    url.searchParams.append("add_user[]", user_id);
    window.location = url
  }
}

export { ParticipationSelect }
