public with sharing class ScheduleDashboardToExtUserController {
    @AuraEnabled(cacheable=true)
    public static List<DashboardWrapper> getDashboards() {
        List<DashboardWrapper> dashboardList = new List<DashboardWrapper>();

        // Parse allowed folders
        List<String> allowedFolders = new List<String>();
        String foldersLabel = '';
        try {
            foldersLabel = System.Label.ScheduleDashboardAllowedFolders;
        } catch(Exception e) {
            // Fallback or ignore
        }
        if (String.isNotBlank(foldersLabel)) {
            for (String folder : foldersLabel.split(',')) {
                allowedFolders.add(folder.trim());
            }
        }

        // Identify already scheduled dashboards to exclude them
        Set<Id> scheduledDashboardIds = new Set<Id>();
        for (CronTrigger ct : [
            SELECT CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'ScheduleDashboardToExternalUse%'
        ]) {
            String jobName = ct.CronJobDetail.Name;
            Integer lastIndex = jobName.lastIndexOf('_');
            if (lastIndex != -1) {
                String dashboardIdStr = jobName.substring(lastIndex + 1);
                try {
                    if (
                        dashboardIdStr.startsWith('01Z') &&
                        (dashboardIdStr.length() == 15 ||
                        dashboardIdStr.length() == 18)
                    ) {
                        scheduledDashboardIds.add((Id) dashboardIdStr);
                    }
                } catch (Exception e) {
                    // Ignore format errors
                }
            }
        }

        List<Dashboard> queryResults;
        if (!allowedFolders.isEmpty()) {
            queryResults = [
                SELECT Id, Title, DeveloperName, FolderName
                FROM Dashboard
                WHERE FolderName IN :allowedFolders AND Id NOT IN :scheduledDashboardIds
                ORDER BY Title
            ];
        } else {
            queryResults = [
                SELECT Id, Title, DeveloperName, FolderName
                FROM Dashboard
                WHERE Id NOT IN :scheduledDashboardIds
                ORDER BY Title
            ];
        }

        for (Dashboard d : queryResults) {
            DashboardWrapper wrap = new DashboardWrapper();
            wrap.dashboardId = d.Id;
            wrap.dashboardName = d.Title;
            wrap.folderName = d.FolderName;
            dashboardList.add(wrap);
        }
        return dashboardList;
    }

    public class DashboardWrapper {
        @AuraEnabled
        public String dashboardId;
        @AuraEnabled
        public String dashboardName;
        @AuraEnabled
        public String folderName;
    }

    public class ScheduleRequest {
        @InvocableVariable(
            required=true
            label='Dashboard ID'
            description='The ID of the Salesforce dashboard to schedule'
        )
        public Id dashboardId;
    }

    @InvocableMethod(
        label='Schedule Dashboard to External User'
        description='Schedules the selected dashboard to run weekly and send email to external user'
    )
    public static List<String> scheduleDashboard(List<ScheduleRequest> requests) {
        List<String> jobIds = new List<String>();
        for (ScheduleRequest req : requests) {
            if (req.dashboardId != null) {
                // Fetch dashboard name to make the job name recognizable
                List<Dashboard> dashboards = [
                    SELECT Title
                    FROM Dashboard
                    WHERE Id = :req.dashboardId
                    LIMIT 1
                ];
                String dashboardName = !dashboards.isEmpty() ? dashboards[0].Title : 'Dashboard';

                // Truncate name if it exceeds length to stay within 80 characters limit
                String prefix = 'ScheduleDashboardToExternalUser_';
                String suffix = '_' + req.dashboardId;
                Integer maxNameLen = 80 - prefix.length() - suffix.length();
                if (dashboardName.length() > maxNameLen) {
                    dashboardName = dashboardName.substring(0, maxNameLen);
                }

                // Job Name
                String jobName = prefix + dashboardName + suffix;

                // Check if a job with this name already exists
                List<CronTrigger> existingJobs = [
                    SELECT Id
                    FROM CronTrigger
                    WHERE CronJobDetail.Name = :jobName
                    LIMIT 1
                ];

                if (existingJobs.isEmpty()) {
                    // Schedule for weekly on Sunday at 3:00 AM (e.g. '0 0 3 ? * SUN *')
                    String cronExp = '0 0 3 ? * SUN';
                    Id jobId = System.schedule(
                        jobName,
                        cronExp,
                        new ScheduleDashboardToExtUserSchedular(req.dashboardId)
                    );
                    jobIds.add(jobId);
                } else {
                    jobIds.add(existingJobs[0].Id);
                }
            } else {
                jobIds.add(null);
            }
        }
        return jobIds;
    }

    @AuraEnabled
    public static List<String> scheduleDashboardsLwc(
        List<String> dashboardIds,
        String frequency
    ) {
        if (dashboardIds == null || dashboardIds.isEmpty()) {
            throw new AuraHandledException('At least one Dashboard ID is required.');
        }
        if (String.isBlank(frequency)) {
            frequency = 'Weekly';
        }

        List<String> jobIds = new List<String>();

        // Fetch dashboard names in bulk
        Map<Id, Dashboard> dashboardsMap = new Map<Id, Dashboard>(
            [
                SELECT Id, Title
                FROM Dashboard
                WHERE Id IN :dashboardIds
            ]
        );

        for (String dashboardId : dashboardIds) {
            Dashboard d = dashboardsMap.get(dashboardId);
            String dashboardName = d != null ? d.Title : 'Dashboard';

            String prefix = 'ScheduleDashboardToExternalUser_';
            String suffix = '_' + frequency + '_' + dashboardId;
            Integer maxNameLen = 80 - prefix.length() - suffix.length();
            if (dashboardName.length() > maxNameLen) {
                dashboardName = dashboardName.substring(0, maxNameLen);
            }

            String jobName = prefix + dashboardName + suffix;

            List<CronTrigger> existingJobs = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
                LIMIT 1
            ];

            if (existingJobs.isEmpty()) {
                String cronExp = '0 55 23 ? * SUN'; // Weekly on Sunday at 11:55 PM
                if ('Daily'.equalsIgnoreCase(frequency)) {
                    cronExp = '0 55 23 * * ?'; // Daily at 11:55 PM
                } else if ('Monthly'.equalsIgnoreCase(frequency)) {
                    cronExp = '0 55 23 1 * ?'; // Monthly (Last day of month or 1st of month at 11:55 PM)
                }

                Id jobId = System.schedule(
                    jobName,
                    cronExp,
                    new ScheduleDashboardToExtUserSchedular(dashboardId)
                );
                jobIds.add(jobId);
            } else {
                jobIds.add(existingJobs[0].Id);
            }
        }
        return jobIds;
    }
}
