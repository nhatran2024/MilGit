/**
@description: Voice Call handler for multiple operations such as insert, update, delet with before and after
@createDate:  5/17/24
**/

public with sharing class VoiceCallTriggerHandler {
    private boolean triggerIsExecuting=false;
    private integer triggerSize=0;
    public VoiceCallTriggerHelper helper;
    public VoiceCallTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new VoiceCallTriggerHelper();
    }
    // public void beforeInsert(List<VoiceCall> newVoiceCalls) {
    // }
    // public void beforeUpdate(List<VoiceCall> oldVoiceCalls, List<VoiceCall> newVoiceCalls, Map<ID, SObject> oldVoiceCallsMap, Map<ID, SObject> newVoiceCallsMap) {
    // }
    // public void beforeDelete(List<VoiceCall> oldVoiceCalls, Map<ID, SObject> oldVoiceCallsMap) {
    // }

    // public void afterInsert(List<VoiceCall> newVoiceCalls, Map<ID, SObject> newVoiceCallsMap) {
    // }
    public void afterUpdate(List<VoiceCall> oldVoiceCalls, List<VoiceCall> newVoiceCalls, Map<ID, SObject> oldVoiceCallsMap, Map<ID, SObject> newVoiceCallsMap) {
        helper.componentRefreshPE();
    }
    // public void afterDelete(List<VoiceCall> oldVoiceCalls, Map<ID, SObject> oldVoiceCallsMap) {
    // }
    // public void afterUndelete(List<VoiceCall> newVoiceCalls, Map<ID, SObject> newVoiceCallsMap) {
    // }
}