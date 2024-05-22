/*
@description Test class for "callerIntentController" - SAL-2566
@param None
@return None
*/

@isTest
public class callerIntentControllerTest {
    public callerIntentControllerTest() {

    }

    public static final string accountRecordType = 'Person Account';
    public static final string sObjectType = 'Account';
    public static final string accountName = 'Test Account';
    public static final string leadName = 'Lead Account';
    public static final string laserName = 'Laser Account';

    public static final string OUTBOUND = 'Outbound';
    public static final string INBOUND = 'Inbound';
    public static final string CONTACTCENTER = 'ContactCenter';

    public static string clientPhone = '';
    public static string clientPicklist = '';
    public static string leadPhone = '';
    public static string leadPicklist = '';
    public static string laserPhone = '';
    public static string laserPicklist = '';

    @TestSetup
    public static void testDataCreation() {

        DateTime testDate = System.now();


        String RecTypeId= [select Id from RecordType where (Name=:accountRecordType) and (SobjectType=:sObjectType)].Id;

        Account testAccount = new Account(LastName = accountName,Phone = '+11234567892', RecordTypeID = RecTypeId);
        insert testAccount;

        
        Account testAccount2 = new Account(LastName = laserName,Phone = '+11234599892', RecordTypeID = RecTypeId);
        insert testAccount2;


        Lead testLead = new Lead(FirstName = 'Tester',
                                LastName = leadName,
                                Status = 'New',
                                Email = 'PardotLead@test.invalid.com',
                                leadsource = 'Self-Schedule Site',
                                company = 'Milan Laser');
        insert testLead;

        Id testCallCenterID = [SELECT Id FROM CallCenter WHERE Name LIKE '%Milan%' LIMIT 1].get(0).Id;

        
        Map<String, Caller_Intent_Setting__mdt> ciMetadata = Caller_Intent_Setting__mdt.getAll();

        for (String name : ciMetadata.keyset()) {
            System.debug('---' + ciMetadata.get(name));
            if (ciMetadata.get(name).group__c == 'client') {
                if (ciMetadata.get(name).type__c == 'phone') {
                    clientPhone = ciMetadata.get(name).value__c;
                }
                if (ciMetadata.get(name).type__c == 'picklist') {
                    clientPicklist = ciMetadata.get(name).value__c;
                }
            }

            if (ciMetadata.get(name).group__c == 'lead') {
                if (ciMetadata.get(name).type__c == 'phone') {
                    leadPhone = ciMetadata.get(name).value__c;
                }
                if (ciMetadata.get(name).type__c == 'picklist') {
                    leadPicklist = ciMetadata.get(name).value__c;
                }
            }

            if (ciMetadata.get(name).group__c == 'laser') {
                if (ciMetadata.get(name).type__c == 'phone') {
                    laserPhone = ciMetadata.get(name).value__c;
                }
                if (ciMetadata.get(name).type__c == 'picklist') {
                    laserPicklist = ciMetadata.get(name).value__c;
                }
            }
        }

        VoiceCall clientTestVoiceCall = new VoiceCall(CallType = INBOUND, NF_Account__c = testAccount.Id, CallCenterId = testCallCenterID , VendorType = CONTACTCENTER ,CallStartDateTime = testDate, CallEndDateTime = testDate, FromPhoneNumber = '+18575576988', ToPhoneNumber = clientPhone, Client_Associated__c = true);
        insert clientTestVoiceCall;

        VoiceCall leadTestVoiceCall = new VoiceCall(CallType = INBOUND, NF_Lead__c = testLead.Id, CallCenterId = testCallCenterID , VendorType = CONTACTCENTER ,CallStartDateTime = testDate, CallEndDateTime = testDate, FromPhoneNumber = '+18575576988', ToPhoneNumber = leadPhone, Lead_Associated__c = true);
        insert leadTestVoiceCall;

        VoiceCall defaultTestVoiceCall = new VoiceCall(CallType = OUTBOUND, CallCenterId = testCallCenterID , VendorType = CONTACTCENTER ,CallStartDateTime = testDate, CallEndDateTime = testDate, FromPhoneNumber = '+18575576988', ToPhoneNumber = laserPhone);
        insert defaultTestVoiceCall;
    }

    @isTest
    static void getPicklistForClient() {
        Account accountRecord = [Select id from Account where LastName = :accountName limit 1];
        List<VoiceCall> vc = [Select id from VoiceCall where CallType = :INBOUND and NF_Account__c =:accountRecord.Id]; 
        callerIntentController.wrapperCallIntentClass ci = callerIntentController.getPicklist(vc[0].Id);
        String jsonStr = JSON.serialize(ci);
        System.assertEquals(true, (jsonStr.contains('Appointment')), 'Should have appointment in the picklist');

    }
    
    @isTest
    static void getPicklistForLead() {
        Lead leadRecord = [Select id from Lead where LastName = :leadName limit 1];
        List<VoiceCall> vc = [Select id from VoiceCall where CallType = :INBOUND and NF_Lead__c =:leadRecord.Id]; 
        callerIntentController.wrapperCallIntentClass ci = callerIntentController.getPicklist(vc[0].Id);
        String jsonStr = JSON.serialize(ci);
        System.assertEquals(true, (jsonStr.contains('Lead Inquiry')), 'Should have Lead Inquiry in the picklist');
    }

    @isTest
    static void getPicklistForDefault() {
        Account acctRecord = [Select id from Account where LastName = :laserName limit 1];
        Test.startTest();
        List<VoiceCall> vc = [Select id, NF_Account__c from VoiceCall where CallType = :OUTBOUND]; 
        callerIntentController.wrapperCallIntentClass ci = callerIntentController.getPicklist(vc[0].Id);
        String jsonStr = JSON.serialize(ci);
        System.assertEquals(true, (jsonStr.contains('Chiller')), 'Should have Chiller in the picklist');
        vc[0].NF_Account__c = acctRecord.Id;
        update vc;
        Test.stopTest();
        ci = callerIntentController.getPicklist(vc[0].Id);
        jsonStr = JSON.serialize(ci);
        System.assertEquals(false, (jsonStr.contains('Chiller')), 'Should NOT have Chiller in the picklist');




    }


}