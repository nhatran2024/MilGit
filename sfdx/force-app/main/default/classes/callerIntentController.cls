/*
@description Apex class "callerIntentController" - SAL-2566.
@param Voice Call ID
@return A wrapper contains: saved picked values, picklist and voice record ID (use for trigger lwc wire)
*/

public without sharing class callerIntentController {

    @AuraEnabled(cacheable=true)
    public static wrapperCallIntentClass getPicklist(String voiceCallId) {

        wrapperCallIntentClass ci = new wrapperCallIntentClass();

        //List for bucketting data from custom metadata base on their group and type
        // ** Phone **
        List<String> clientPhoneList = new List<String>();
        List<String> leadPhoneList = new List<String>();
        List<String> laserPhoneList = new List<String>();

        // ** Call Type **
        List<String> callInboundList = new List<String>();
        List<String> callOutboundList = new List<String>();

        // ** Reason picklists **
        List<String> clientPicklist = new List<String>();
        List<String> leadPicklist = new List<String>();
        List<String> laserPicklist = new List<String>();

            
        Map<String, Caller_Intent_Setting__mdt> ciMetadata = Caller_Intent_Setting__mdt.getAll();
        for (String name : ciMetadata.keyset()) {

            getMetaPicklistValue(clientPicklist, ciMetadata.get(name), 'client', 'picklist');
            getMetaPicklistValue(leadPicklist, ciMetadata.get(name), 'lead', 'picklist');
            getMetaPicklistValue(laserPicklist, ciMetadata.get(name), 'laser', 'picklist');

            getMetaPicklistValue(callInboundList, ciMetadata.get(name), 'inbound', 'picklist');
            getMetaPicklistValue(callOutboundList, ciMetadata.get(name), 'outbound', 'picklist');

        }
        
        VoiceCall vc = [SELECT id, CallResolution, CallOrigin, CallType, Primary_call_reason__c, Secondary_call_reason__c, NF_Lead__c, NF_Account__c, ToPhoneNumber, fromPhoneNumber, Client_Associated__c, Lead_Associated__c from VoiceCall WHERE id = :voiceCallId];

        //-- return picklist for primary call reason
        if (vc != null) {
            If (vc.NF_Account__c <> null) {    
                ci.apexIntentPickList = clientPicklist;
            }
            else If (vc.NF_Lead__c <> null) {            
                ci.apexIntentPickList = leadPicklist;
            }
            else {
                ci.apexIntentPickList = clientPicklist;
                ci.apexIntentPickList.addAll(leadPicklist);
                ci.apexIntentPickList.addAll(laserPicklist);
            }
        
            //-- return primary call reason, secondary call reason. 
            ci.apexIntentPickedVal = !String.isBlank(vc.Primary_call_reason__c) ? vc.Primary_call_reason__c : '';
            ci.apexReasonPickedVal = !String.isBlank(vc.Secondary_call_reason__c) ? vc.Secondary_call_reason__c : '';
            ci.apexIntentNewVal = ci.apexIntentPickList.contains(vc.Primary_call_reason__c)? vc.Primary_call_reason__c : '';
            
            //-- outcome list does not get chang as it binds to the calltype which can't be altered.
            ci.apexOutcomePickList= !String.isBlank(vc.CallType) && 
                                    (vc.CallType.toLowerCase() == 'outbound' || vc.CallType.toLowerCase() == 'callback')? callOutboundList : callInboundList;

            //-- recordId to help find picklist base on record type and serve as trigger for wire to execute.
            ci.voiceRecordId = Schema.SObjectType.VoiceCall.getRecordTypeInfosByName().get('Master').getRecordTypeId();
            //-- this value shoudn't change once previously saved as it bind to the calltype
            ci.apexOutcomePickedVal = !String.isBlank(vc.CallResolution) ? vc.CallResolution : '';
        }

     return ci;
    }

    public class wrapperCallIntentClass{
        @AuraEnabled public List<String> apexIntentPickList {get;set;}
        @AuraEnabled public List<String> apexOutcomePickList {get;set;}
        //Pick value from query
        @AuraEnabled public String apexIntentPickedVal {get;set;}
        @AuraEnabled public String apexReasonPickedVal {get;set;}
        @AuraEnabled public String apexOutcomePickedVal {get;set;}
        //the new value is basically blank, this apply to the scenario when the previously picked option is not the picklist
        //then we need to reset so user can select new value
        @AuraEnabled public String apexIntentNewVal {get;set;}
        @AuraEnabled public String voiceRecordId {get;set;}
    }
    
    /*
    @description    Method to get final value from a custom metada record.  
                    We traverser from top level to lower. Metadata -> group -> type -> values and store into picklist
    @param          Picklist, Metadarecord, group, type
    @return         None
    */
    private static void getMetaPicklistValue (List<String> pickList, Caller_Intent_Setting__mdt ciMetadata, string groupName, string type) {
        if (ciMetadata.group__c == groupName) {
            if (ciMetadata.type__c == type) {
                pickList.add(ciMetadata.value__c);
            }        
        }
    }

}