import CheckboxSelectAll from "@stimulus-components/checkbox-select-all"
import { toggleLieuSelectionField } from "../components/plage_ouverture";

export default class extends CheckboxSelectAll {
  toggle(e) {
    super.toggle(e)
    toggleLieuSelectionField()
  }
}
