/**
 * @description Test class for AccountHandler.
 * Covers scenarios for:
 *   - Defaulting Industry to 'Technology' on insert.
 *
 * @group Tests
 */
@IsTest
private class AccountHandlerTest {

    // ─── Constants ───────────────────────────────────────────────────────
    private static final String INDUSTRY_TECH = 'Technology';

    /**
     * @description Helper to check if 'Technology' is a valid Industry value
     * in the current org. Keeps tests resilient across org configurations.
     * @return Boolean indicating whether 'Technology' is a valid Account.Industry picklist value.
     */
    private static Boolean isTechnologyAllowedIndustry() {
        Set<String> allowed = new Set<String>();
        for (Schema.PicklistEntry pe : Account.Industry.getDescribe().getPicklistValues()) {
            allowed.add(pe.getValue());
        }
        return allowed.contains(INDUSTRY_TECH);
    }

    /**
     * @description Creates a standard test user for System.runAs() calls.
     * @return A User record with the Standard User profile.
     */
    private static User createTestUser() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            Alias             = 'tuser',
            Email             = 'testuser@accounthandlertest.example.com',
            EmailEncodingKey  = 'UTF-8',
            LastName          = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            ProfileId         = stdProfile.Id,
            TimeZoneSidKey    = 'America/Los_Angeles',
            UserName          = 'testuser' + DateTime.now().getTime() + '@accounthandlertest.example.com'
        );
    }

    // ═════════════════════════════════════════════════════════════════════
    //  Industry defaulting tests
    // ═════════════════════════════════════════════════════════════════════

    /**
     * @description On insert, when Industry is blank, the trigger/helper
     * should default Industry to 'Technology' when that value is allowed.
     */
    @IsTest
    static void createSingleWithBlankIndustryShouldSetTechnologyWhenAllowed() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Account acc = new Account(
                Name = 'Industry Default Blank'
            );

            insert acc;
            acc = [
                SELECT Industry
                FROM Account
                WHERE Id = :acc.Id
            ];

            if (isTechnologyAllowedIndustry()) {
                System.assertEquals(
                    INDUSTRY_TECH,
                    acc.Industry,
                    'Industry should default to Technology when allowed and initially blank.'
                );
            } else {
                System.assertEquals(
                    null,
                    acc.Industry,
                    'Industry should remain null when Technology is not a valid Industry value.'
                );
            }
        }
    }

    /**
     * @description On insert, when Industry is pre-populated, the trigger/helper
     * should not override it with the default Technology value.
     */
    @IsTest
    static void createSingleWithExistingIndustryShouldNotOverride() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String originalIndustry = 'Banking';
            Account acc = new Account(
                Name     = 'Industry Preserved',
                Industry = originalIndustry
            );

            insert acc;
            acc = [
                SELECT Industry
                FROM Account
                WHERE Id = :acc.Id
            ];

            System.assertEquals(
                originalIndustry,
                acc.Industry,
                'Industry set before insert should not be overridden by the default logic.'
            );
        }
    }
}