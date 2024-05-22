import { LightningElement, wire, api, track } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import VOICE_OBJECT from "@salesforce/schema/VoiceCall";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CALLER_INTENT from "@salesforce/schema/VoiceCall.Primary_Call_Reason__c";
import CALL_REASON from "@salesforce/schema/VoiceCall.Secondary_call_reason__c";
import DESCRIPTION from "@salesforce/schema/VoiceCall.Description";
import GETPICKLISTFILTER from '@salesforce/apex/callerIntentController.getPicklist';
import CALL_RESOLUTION from "@salesforce/schema/VoiceCall.CallResolution";
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { refreshApex } from "@salesforce/apex";

export default class CallerIntentLWC extends LightningElement {
    @api recordId;
    @api channelName = '/event/Refresh_Caller_Intent_LWC__e';

    wiredPicklistResult;

    voiceRecordTypeId;
    callIntentPickList;
    callIntentPickListDep;
    filterIntentPicklistDep;
    outcomePickList;

    voiceObj = VOICE_OBJECT;
    subscription = {};


    callerIntentField = CALLER_INTENT;  
    callReasonField = CALL_REASON;
    callResolutionField = CALL_RESOLUTION;
    descriptionField = DESCRIPTION;

    showSpinner = false;

    callIntentDbVal = '';
    callReasonDbVal = '';
    outcomeDbVal = '';

    connectedCallback() {
        const self = this;
        const callbackFunction = function (response) {
            self.refreshMyData();
        };
        subscribe(this.channelName, -1, callbackFunction).then(response => {
            this.subscription = response
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
        });
        this.subscription = null;
    }


    refreshMyData() { 
        if (this.recordId) {
            console.log('---invoke refresh');
            //make sure voice call record ID available before call refresh
            refreshApex(this.wiredPicklistResult);
        }
        else {
            console.log('---not ready');
        }
    }

    //Call backend APEX - This is where first call starts in LWC
    @wire (GETPICKLISTFILTER,{voiceCallId: '$recordId'})
	filteredList(result){
        console.log('===APEX returned result' + JSON.stringify(result));
        this.wiredPicklistResult = result;
        this.voiceRecordTypeId = '';
		if(result.data) {
            let data = result.data;

            //Create Primary Reason/Caller Intent picklist
            if (result.data.apexIntentPickList) {
                let intentArr = [];
                result.data.apexIntentPickList.forEach((option) => {
                    intentArr.push({"label" : option, "value" : option });
                });
                this.callIntentPickList = intentArr;
            }

            //-- Create Call Outcome picklist
            if (result.data.apexOutcomePickList) {
                let outcomeArr = [];
                result.data.apexOutcomePickList.forEach((option) => {
                    outcomeArr.push({"label" : option, "value" : option });
                });
                this.outcomePickList = outcomeArr;
            }

            if (data.apexIntentNewVal) {
                this.callIntentDbVal = data.apexIntentNewVal;
                this.callReasonDbVal = data.apexReasonPickedVal;
            }
            else {
                this.callIntentDbVal = '';
                this.callReasonDbVal = '';
            }
            this.outcomeDbVal = result.data.apexOutcomePickedVal;
            this.voiceRecordTypeId = data.voiceRecordId;
            
		}else {
            if (result.error) {
                console.log(result.error.body.message);
			    this.error = result.error.body.message;
                this.showErrorToast();
            }
		}
	}

    //get Secondary Call Reason
    @wire(getPicklistValues, { recordTypeId: "$voiceRecordTypeId", fieldApiName: CALL_REASON })
    picklistDepResults({ error, data }) {

        if (data) {
            //dependent picklist has controller values, so we want to keep everything, not just values.
            this.callIntentPickListDep = data;
            let key = this.callIntentPickListDep.controllerValues[this.callIntentDbVal];
            this.filterIntentPicklistDep = this.callIntentPickListDep.values.filter(opt => opt.validFor.includes(key));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.callIntentPickListDep = undefined;
        }
    }

    handleIntentChange(event) {
        let key = this.callIntentPickListDep.controllerValues[event.detail.value];
        this.callIntentDbVal = event.detail.value;
        this.filterIntentPicklistDep = this.callIntentPickListDep.values.filter(opt => opt.validFor.includes(key));
        this.callReasonDbVal = null;
    }

    handleReasonChange(event) {
        // this.callReasonVal = event.detail.value;
        this.callReasonDbVal = event.detail.value;
    }

    handleOutcomeChange(event) {
        this.outcomeDbVal = event.detail.value;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.showSpinner = true;

        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                console.log(input_Field_Reference.reportValidity());
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
 
        if(All_Compobox_Valid){
            console.log('Intent:' + this.callIntentDbVal + ', Reason: ' + this.callReasonDbVal);
            const fields = event.detail.fields;
            fields.Primary_Call_Reason__c = this.callIntentDbVal;
            fields.Secondary_call_reason__c = this.callReasonDbVal;
            fields.CallResolution = this.outcomeDbVal;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
        else {
            //in event of failed validation, turn off the spinner
            this.showSpinner = false;
        }

    }

    handleSuccess(event){
        const payload = event.detail;
        this.showSpinner = false;
        this.showSuccessToast();        

    }

    handleError(event){
        console.log('Something went ... not well');
        console.log(JSON.stringify(event));
        this.showSpinner = false;
        if (event.detail.detail) {
            this.error = event.detail.detail;
            this.showErrorToast();
        }
    }

    showSuccessToast() {
        const event = new ShowToastEvent({
            title: 'Voice Call Record',
            message: 'Saved Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showErrorToast() {
        const event = new ShowToastEvent({
            title: 'Voice Call Record - Caller Intent',
            message: 'Error: ' + this.error,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }


}