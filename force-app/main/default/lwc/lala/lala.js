import { LightningElement, api, wire } from "lwc";
import addLala from "@salesforce/apex/LalaController.addLala";
// import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";

export default class Lala extends LightningElement {
	@api recordId
	// urlId;
	isExecuting = false;

	// Workaround to get recordId from page reference,
	// because "@api recordId" is unreliable in a headless QuickAction
	// @wire(CurrentPageReference)
	// getStateParameters(currentPageReference) {
	// 	if (currentPageReference) {
	// 		this.urlId = currentPageReference.attributes.recordId;
	// 	}
	// }

	@api async invoke() {
		if (this.isExecuting) {
			return;
		}
		this.isExecuting = true;

		// Give user feedback we are starting the action
		this.fireToast("info", "dismissible", "Action started... please wait");

		try {
			await addLala({ recordId: this.recordId });
			await this.refresh();
			this.fireToast("success", "dismissible", "Whoohoooo... job done!");
		} catch (error) {
			this.fireToast("error", "sticky", error.body.message);
		}

		this.isExecuting = false;
	}

	fireToast(variant, mode, message) {
		let toastMessage = new ShowToastEvent({
			title: "Lala",
			variant: variant,
			mode: mode,
			message: message,
		});
		this.dispatchEvent(toastMessage);
	}

	async refresh() {
		let contactRecord = {
			fields: {
				Id: this.recordId
			},
		};
		await updateRecord(contactRecord);
	}
}