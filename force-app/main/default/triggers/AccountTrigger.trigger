/**
 * Account Trigger
 * Creates an Opportunity when an Account is created
 */
trigger AccountTrigger on Account (
    after insert
) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new, Trigger.newMap);
    }
}