/**
* @description Handler class for Account trigger logic.
* Contains helper methods for defaulting standard fields on create.
*/
public with sharing class AccountHandler {

    /**
     * @description Main entry point called from AccountTrigger.
     * Routes trigger events to the appropriate handler methods.
     * @param newAccounts List of new Account records from Trigger.new
     * @param oldAccountMap Map of old Account records from Trigger.oldMap
     * @param operationType The System.TriggerOperation enum value
     */
    public static void handleTrigger(List<Account> newAccounts, Map<Id, Account> oldAccountMap, System.TriggerOperation operationType) {
        switch on operationType {
            when BEFORE_INSERT {
                setIndustryToTechnologyOnCreate(newAccounts);
            }
        }
    }

    /**
     * @description On Account create, sets Industry to 'Technology'.
     * Safely skips setting Industry if 'Technology' is not a valid Account.Industry picklist value.
     * @param newAccounts List of new Account records from Trigger.new
     */
    public static void setIndustryToTechnologyOnCreate(List<Account> newAccounts) {
        // Account.Industry is a standard picklist; to avoid insert failures, only set it when the value is valid.
        Set<String> allowedIndustryValues = new Set<String>();
        for (Schema.PicklistEntry pe : Account.Industry.getDescribe().getPicklistValues()) {
            allowedIndustryValues.add(pe.getValue());
        }

        for (Account acc : newAccounts) {
            if (String.isBlank(acc.Industry) && allowedIndustryValues.contains('Technology')) {
                acc.Industry = 'Technology';
            }
        }
    }

}