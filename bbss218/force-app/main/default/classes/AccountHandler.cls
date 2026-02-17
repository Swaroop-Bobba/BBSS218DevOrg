/**
 * @description Handler class for Account trigger logic.
 * Contains validation methods for the Retrive__c field on create and update operations.
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
                validateRetriveOnCreate(newAccounts);
            }
            when BEFORE_UPDATE {
                validateRetriveOnUpdate(newAccounts, oldAccountMap);
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

    /**
     * @description Validates that the Retrive__c field is populated on newly created Accounts.
     * Adds an error to any Account where Retrive__c is null or blank.
     * @param newAccounts List of new Account records from Trigger.new
     */
    public static void validateRetriveOnCreate(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            Object retriveValue = acc.get('Retrive__c');
            Boolean isMissing = retriveValue == null
                || (retriveValue instanceof String && String.isBlank((String) retriveValue));

            if (isMissing) {
                acc.addError('Retrive should be filled.');
            }
        }
    }

    /**
     * @description Prevents users from clearing the Retrive__c field on update.
     * Users can change the value but cannot remove it if it was previously set.
     * @param newAccounts List of updated Account records from Trigger.new
     * @param oldAccountMap Map of old Account records from Trigger.oldMap
     */
    public static void validateRetriveOnUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountMap.get(acc.Id);

            Object oldValue = oldAcc.get('Retrive__c');
            Boolean hadValue = oldValue != null
                && !(oldValue instanceof String && String.isBlank((String) oldValue));

            if (hadValue) {
                Object newValue = acc.get('Retrive__c');
                Boolean isNowEmpty = newValue == null
                    || (newValue instanceof String && String.isBlank((String) newValue));

                if (isNowEmpty) {
                    acc.addError('Retrive value is required in this stage.');
                }
            }
        }
    }

}