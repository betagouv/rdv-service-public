import { Controller } from "@hotwired/stimulus"

import {RdvPlanCalendar} from "../components/rdv-plan-calendar";

export default class extends Controller {
  connect() {
    new RdvPlanCalendar()
  }
}