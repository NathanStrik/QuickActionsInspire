import { LightningElement, api, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from "lightning/navigation";
import componentLabel from "@salesforce/label/c.Number_Adder_Header";

export default class NumberAdder extends LightningElement {

	@api recordId;

	sum = 0;
	isQuickAction = false;
	headerLabel = "";
	labels = { componentLabel }

	@wire(CurrentPageReference)
	getStateParameters(pRef) {
		this.isQuickAction = pRef.type === "standard__quickAction";
		this.headerLabel = this.isQuickAction ? this.labels.componentLabel : "";
	}

	handleAddition() {
		const num1 = parseInt(this.template.querySelector("[data-id='num1']").value);
		const num2 = parseInt(this.template.querySelector("[data-id='num2']").value);
		this.sum = num1 + num2;
	}

	handleCancel() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

}