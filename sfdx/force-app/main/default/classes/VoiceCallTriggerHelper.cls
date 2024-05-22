/**
@description: Helper class that use in voice call Trigger
@createDate:  5/17/24
**/

public with sharing class VoiceCallTriggerHelper {
    public VoiceCallTriggerHelper() {
        System.debug('Inside VoiceCallTriggerHelper Constructor');
    }
    public void componentRefreshPE() {
        System.debug('componentRefreshPE');
        Refresh_Caller_Intent_LWC__e refreshEvent = new Refresh_Caller_Intent_LWC__e();
        EventBus.publish(refreshEvent);
    }
}