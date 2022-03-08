// See also AgentsHelper::planning_agent_select
class RdvUserSelect {
  constructor() {
    this.$select = $(".js-rdv-user-select")
    if (!this.$select) return

    this.$select.on("change", this.userSelected)

    // console.log(this.$select.dataset)
    // if (this.$select.dataset.scrollToBottom === "true") {
    //   document.body.scrollTop = document.body.scrollHeight;
    // }
  }

  userSelected = (event) => {
    let url = new URL(window.location.href);
    let user_id = this.$select.select2("data")[0].element.value;
    url.searchParams.append("add_user[]", user_id);
    Turbolinks.visit(url);
  }
}

export { RdvUserSelect }
