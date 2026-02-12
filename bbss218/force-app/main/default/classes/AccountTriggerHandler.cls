public class AccountTriggerHandler {
    public static void handleAfterInsert(List<Account> newAccounts) {
        List<Id> accIds = new List<Id>();
        for (Account acc : newAccounts) {
            accIds.add(acc.Id); // Only pass Ids
        }

        // Call Future method with only Ids
       // AccountAsyncHandler.sendWelcomeEmailAsync(accIds);
    }
}