public class EmployeeSendEmail {
    public static void sendEmailNotify(List<Employee__c> newEmployees) {
        List<Id> empIds = new List<Id>();
        for (Employee__c emp : newEmployees) {
            if (emp.Email__c != null) {
                empIds.add(emp.Id);
            }
        }   
        if (!empIds.isEmpty()) {
            sendEmailsAsync(empIds);
        }
    }

    @future
    private static void sendEmailsAsync(List<Id> employeeIds) {
        List<Employee__c> employees = [SELECT Id, Email__c FROM Employee__c WHERE Id IN :employeeIds];
        
        //Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Welcome_Employee_Template' LIMIT 1].Id;

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		 
        for (Employee__c emp : employees) {
            if (emp.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { emp.Email__c });
                email.setSubject('Welocome ' );
                email.setPlainTextBody('Hi,\nWelcome to the Organization\n\nAll the Best');
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}