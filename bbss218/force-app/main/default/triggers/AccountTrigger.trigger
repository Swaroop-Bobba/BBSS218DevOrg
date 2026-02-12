trigger AccountTrigger on Account (before insert, before update) {
    AccountHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}