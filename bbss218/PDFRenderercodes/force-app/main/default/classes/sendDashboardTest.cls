@isTest
public class sendDashboardTest {
    @isTest
    static void testExecute() {
        Test.startTest();
        // Call the execute method
        sendDashboard scheduler = new sendDashboard();
        scheduler.execute(null);
        Test.stopTest();
    }

    @isTest(seeAllData='True')
    static void testDashboardAttachments() {
        Test.startTest();
        sendDashboard.sendEmail();
        Test.stopTest();
    }
}
