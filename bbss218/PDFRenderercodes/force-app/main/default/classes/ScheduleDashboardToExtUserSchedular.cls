public with sharing class ScheduleDashboardToExtUserSchedular implements Schedulable {
    private Id dashboardId;

    public ScheduleDashboardToExtUserSchedular() {
        // Default constructor
    }

    public ScheduleDashboardToExtUserSchedular(Id dashboardId) {
        this.dashboardId = dashboardId;
    }

    public void execute(SchedulableContext sc) {
        if (this.dashboardId != null) {
            runAndEmailDashboard(this.dashboardId);
        }
    }

    @future(callout=true)
    public static void runAndEmailDashboard(Id dashboardId) {
        runAndEmailDashboardInternal(dashboardId);
    }

    private static void runAndEmailDashboardInternal(Id dashboardId) {
        try {
            // Retrieve email(s) from Custom Label
            Set<String> uniqueEmails = new Set<String>();

            String recipientEmail = '';
            try {
                recipientEmail = System.Label.ScheduleDashboardToExternalUserEmail;
            } catch (Exception e) {
                // Fallback or ignore
            }

            // Fallback to report email if dashboard label is blank
            if (String.isBlank(recipientEmail)) {
                try {
                    recipientEmail = System.Label.ScheduleReportToExternalUserEmail;
                } catch (Exception e) {
                    // ignore
                }
            }

            if (String.isNotBlank(recipientEmail)) {
                String normalizedEmail = recipientEmail.replace(';', ',');
                for (String emailStr : normalizedEmail.split(',')) {
                    if (String.isNotBlank(emailStr)) {
                        uniqueEmails.add(emailStr.trim());
                    }
                }
            }

            List<String> toAddresses = new List<String>(uniqueEmails);

            if (toAddresses.isEmpty()) {
                System.debug(
                    'Recipient email is blank. Please configure the Custom Label ScheduleDashboardToExternalUserEmail.'
                );
                return;
            }

            // Retrieve Dashboard Name
            List<Dashboard> dashboards = [
                SELECT Title
                FROM Dashboard
                WHERE Id = :dashboardId
                LIMIT 1
            ];
            String dashboardTitle = !dashboards.isEmpty()
                ? dashboards[0].Title
                : 'Salesforce Dashboard';

            // Get Instance URL dynamically or via Custom Label org_URL
            String orgUrl = URL.getOrgDomainUrl().toExternalForm();
            try {
                if (String.isNotBlank(System.Label.org_URL)) {
                    orgUrl = System.Label.org_URL;
                }
            } catch (Exception e) {
                // ignore
            }

            String dashboardLink = orgUrl + '/' + dashboardId;

            // Setup Email Message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            email.setSubject('Scheduled Dashboard: ' + dashboardTitle);
            email.setPlainTextBody(
                'Hello,\n\nPlease find the link to the scheduled Salesforce dashboard: ' +
                dashboardTitle +
                '.\n\nLink to Dashboard: ' +
                dashboardLink +
                '\n\nBest Regards,\nSalesforce Automated Scheduler'
            );

            // Send Email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            System.debug(
                'Error in runAndEmailDashboard: ' +
                e.getMessage() +
                '\n' +
                e.getStackTraceString()
            );
        }
    }
}
