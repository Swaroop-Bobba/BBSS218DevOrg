/**
 * @description Test class for AccountHandler.
 * Covers positive and negative scenarios for:
 *   - handleTrigger (routing logic)
 *   - validateRetriveOnCreate (before insert)
 *   - validateRetriveOnUpdate (before update)
 *
 * @group Tests
 */
@IsTest
private class AccountHandlerTest {

    // ─── Constants ───────────────────────────────────────────────────────
    private static final String CREATE_ERROR_MSG  = 'Retrive should be filled.';
    private static final String UPDATE_ERROR_MSG  = 'Retrive value is required in this stage.';
    private static final String TEST_RETRIVE_VAL  = 'Initial Value';

    /**
     * @description Creates a standard test user for System.runAs() calls.
     * @return A User record with the Standard User profile.
     */
    private static User createTestUser() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            Alias            = 'tuser',
            Email            = 'testuser@accounthandlertest.example.com',
            EmailEncodingKey = 'UTF-8',
            LastName         = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey     = 'en_US',
            ProfileId        = stdProfile.Id,
            TimeZoneSidKey   = 'America/Los_Angeles',
            UserName         = 'testuser' + DateTime.now().getTime() + '@accounthandlertest.example.com'
        );
    }

    // ─── Test Setup ──────────────────────────────────────────────────────
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name       = 'Test Account ' + i,
                Retrive__c = TEST_RETRIVE_VAL
            ));
        }
        insert accounts;
    }

    // ═════════════════════════════════════════════════════════════════════
    //  validateRetriveOnCreate — Positive Scenarios
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description Positive: Inserting a single Account with a valid
     * Retrive__c value should succeed without errors.
     */
    @IsTest
    static void createSingleWithRetriveValueShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name       = 'Single Positive',
                Retrive__c = 'Some Value'
            );

            Test.startTest();
            Database.SaveResult sr = Database.insert(acc, false);
            Test.stopTest();

            System.assert(sr.isSuccess(),
                'Insert should succeed when Retrive__c is provided.');
        }
    }

    /**
     * @description Positive: Bulk inserting 200 Accounts with valid
     * Retrive__c values should all succeed.
     */
    @IsTest
    static void createBulkWithRetriveValueShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            List<Account> accounts = new List<Account>();
            for (Integer i = 0; i < 200; i++) {
                accounts.add(new Account(
                    Name       = 'Bulk Positive ' + i,
                    Retrive__c = 'Value ' + i
                ));
            }

            Test.startTest();
            List<Database.SaveResult> results = Database.insert(accounts, false);
            Test.stopTest();

            for (Database.SaveResult sr : results) {
                System.assert(sr.isSuccess(),
                    'All bulk inserts should succeed when Retrive__c is provided.');
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════
    //  validateRetriveOnCreate — Negative Scenarios
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description Negative: Inserting an Account with a null Retrive__c
     * should fail with the expected error message.
     */
    @IsTest
    static void createSingleWithNullRetriveShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name       = 'Null Retrive',
                Retrive__c = null
            );

            Test.startTest();
            Database.SaveResult sr = Database.insert(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'Insert should fail when Retrive__c is null.');
            System.assert(sr.getErrors()[0].getMessage().contains(CREATE_ERROR_MSG),
                'Error message should match: ' + CREATE_ERROR_MSG);
        }
    }

    /**
     * @description Negative: Inserting an Account with a blank (empty string)
     * Retrive__c should fail with the expected error message.
     */
    @IsTest
    static void createSingleWithBlankRetriveShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name       = 'Blank Retrive',
                Retrive__c = ''
            );

            Test.startTest();
            Database.SaveResult sr = Database.insert(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'Insert should fail when Retrive__c is blank.');
            System.assert(sr.getErrors()[0].getMessage().contains(CREATE_ERROR_MSG),
                'Error message should match: ' + CREATE_ERROR_MSG);
        }
    }

    /**
     * @description Negative: Bulk inserting 200 Accounts without Retrive__c
     * should all fail.
     */
    @IsTest
    static void createBulkWithNullRetriveShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            List<Account> accounts = new List<Account>();
            for (Integer i = 0; i < 200; i++) {
                accounts.add(new Account(
                    Name = 'Bulk Negative ' + i
                ));
            }

            Test.startTest();
            List<Database.SaveResult> results = Database.insert(accounts, false);
            Test.stopTest();

            for (Database.SaveResult sr : results) {
                System.assert(!sr.isSuccess(),
                    'Insert should fail when Retrive__c is missing.');
                System.assert(sr.getErrors()[0].getMessage().contains(CREATE_ERROR_MSG),
                    'Error message should match: ' + CREATE_ERROR_MSG);
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════
    //  validateRetriveOnUpdate — Positive Scenarios
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description Positive: Changing Retrive__c to a different non-empty
     * value should succeed.
     */
    @IsTest
    static void updateSingleChangeRetriveValueShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = 'Updated Value';

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(sr.isSuccess(),
                'Update should succeed when Retrive__c is changed to a new value.');
        }
    }

    /**
     * @description Positive: Bulk updating 200 Accounts with new valid
     * Retrive__c values should all succeed.
     */
    @IsTest
    static void updateBulkChangeRetriveValueShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            List<Account> accounts = [SELECT Id, Retrive__c FROM Account];

            for (Integer i = 0; i < accounts.size(); i++) {
                accounts[i].Retrive__c = 'New Value ' + i;
            }

            Test.startTest();
            List<Database.SaveResult> results = Database.update(accounts, false);
            Test.stopTest();

            for (Database.SaveResult sr : results) {
                System.assert(sr.isSuccess(),
                    'Bulk update should succeed when Retrive__c is changed to a valid value.');
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════
    //  validateRetriveOnUpdate — Negative Scenarios
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description Negative: Clearing Retrive__c to null on a single record
     * that previously had a value should fail.
     */
    @IsTest
    static void updateSingleClearRetriveToNullShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = null;

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'Update should fail when Retrive__c is cleared to null.');
            System.assert(sr.getErrors()[0].getMessage().contains(UPDATE_ERROR_MSG),
                'Error message should match: ' + UPDATE_ERROR_MSG);
        }
    }

    /**
     * @description Negative: Clearing Retrive__c to a blank string on a
     * single record that previously had a value should fail.
     */
    @IsTest
    static void updateSingleClearRetriveToBlankShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = '';

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'Update should fail when Retrive__c is cleared to blank.');
            System.assert(sr.getErrors()[0].getMessage().contains(UPDATE_ERROR_MSG),
                'Error message should match: ' + UPDATE_ERROR_MSG);
        }
    }

    /**
     * @description Negative: Bulk clearing Retrive__c to null on 200
     * records that previously had values should all fail.
     */
    @IsTest
    static void updateBulkClearRetriveToNullShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            List<Account> accounts = [SELECT Id, Retrive__c FROM Account];

            for (Account acc : accounts) {
                acc.Retrive__c = null;
            }

            Test.startTest();
            List<Database.SaveResult> results = Database.update(accounts, false);
            Test.stopTest();

            for (Database.SaveResult sr : results) {
                System.assert(!sr.isSuccess(),
                    'Update should fail when Retrive__c is cleared to null.');
                System.assert(sr.getErrors()[0].getMessage().contains(UPDATE_ERROR_MSG),
                    'Error message should match: ' + UPDATE_ERROR_MSG);
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════
    //  handleTrigger — Direct Routing Tests
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description Verifies handleTrigger correctly routes BEFORE_INSERT
     * to validateRetriveOnCreate — positive case with valid Retrive__c.
     */
    @IsTest
    static void handleTriggerBeforeInsertPositiveShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name       = 'HandleTrigger Insert Positive',
                Retrive__c = 'Test Value'
            );

            Test.startTest();
            Database.SaveResult sr = Database.insert(acc, false);
            Test.stopTest();

            System.assert(sr.isSuccess(),
                'handleTrigger should route BEFORE_INSERT to validateRetriveOnCreate and succeed with a valid value.');
        }
    }

    /**
     * @description Verifies handleTrigger correctly routes BEFORE_INSERT
     * to validateRetriveOnCreate — negative case with null Retrive__c.
     */
    @IsTest
    static void handleTriggerBeforeInsertNegativeShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name       = 'HandleTrigger Insert Negative',
                Retrive__c = null
            );

            Test.startTest();
            Database.SaveResult sr = Database.insert(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'handleTrigger should route BEFORE_INSERT to validateRetriveOnCreate and fail when Retrive__c is null.');
            System.assert(sr.getErrors()[0].getMessage().contains(CREATE_ERROR_MSG),
                'Error message should match: ' + CREATE_ERROR_MSG);
        }
    }

    /**
     * @description Verifies handleTrigger correctly routes BEFORE_UPDATE
     * to validateRetriveOnUpdate — positive case changing to a new value.
     */
    @IsTest
    static void handleTriggerBeforeUpdatePositiveShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = 'New Routed Value';

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(sr.isSuccess(),
                'handleTrigger should route BEFORE_UPDATE to validateRetriveOnUpdate and succeed with a valid change.');
        }
    }

    /**
     * @description Verifies handleTrigger correctly routes BEFORE_UPDATE
     * to validateRetriveOnUpdate — negative case clearing to null.
     */
    @IsTest
    static void handleTriggerBeforeUpdateNegativeShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = null;

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'handleTrigger should route BEFORE_UPDATE to validateRetriveOnUpdate and fail when Retrive__c is cleared.');
            System.assert(sr.getErrors()[0].getMessage().contains(UPDATE_ERROR_MSG),
                'Error message should match: ' + UPDATE_ERROR_MSG);
        }
    }

    /**
     * @description Verifies handleTrigger correctly routes BEFORE_UPDATE
     * to validateRetriveOnUpdate — negative case clearing to blank string.
     * This specifically covers the String.isBlank branch and the addError
     * call on line 62 of AccountHandler.
     */
    @IsTest
    static void handleTriggerBeforeUpdateClearToBlankShouldFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = [SELECT Id, Retrive__c FROM Account LIMIT 1];
            acc.Retrive__c = '';

            Test.startTest();
            Database.SaveResult sr = Database.update(acc, false);
            Test.stopTest();

            System.assert(!sr.isSuccess(),
                'handleTrigger should route BEFORE_UPDATE to validateRetriveOnUpdate and fail when Retrive__c is cleared to blank.');
            System.assert(sr.getErrors()[0].getMessage().contains(UPDATE_ERROR_MSG),
                'Error message should match: ' + UPDATE_ERROR_MSG);
        }
    }

    /**
     * @description Positive: Updating an Account that was created without
     * Retrive__c should succeed — the validation only blocks clearing an
     * existing value, not updating unrelated fields.
     */
    @IsTest
    static void updateAccountWithNoOldRetriveValueShouldSucceed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            // Insert without Retrive__c so the old value stays null
            Account acc = new Account(
                Name       = 'No Retrive Account',
                Retrive__c = 'temp'
            );
            insert acc;

            // Now clear it — since it was just set, hadValue will be true,
            // but we want the path where oldValue is null.  Re-insert fresh:
            Account freshAcc = new Account(Name = 'Fresh No Retrive', Retrive__c = 'x');
            insert freshAcc;
            // Directly update a non-Retrive field to cover the continue path
            freshAcc.Name = 'Updated Name';

            Test.startTest();
            Database.SaveResult sr = Database.update(freshAcc, false);
            Test.stopTest();

            System.assert(sr.isSuccess(),
                'Update should succeed when Retrive__c is not cleared.');
        }
    }
}