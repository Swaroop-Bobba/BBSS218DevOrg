public without sharing class sendDashboard implements Schedulable {

    public void execute(SchedulableContext ctx) {
        sendEmail();
    }

    @future(callout=true)
    public static void sendEmail() {
        PageReference ref = new PageReference('/apex/ssDashBoardPage');
        String emailLabel = System.Label.Report_Email_Addresses;
        List<String> emailIDs = emailLabel.split(';');
        Blob b;
        if (Test.IsRunningTest()) {
            b = Blob.valueOf('UNIT.TEST');
        } else {
            b = ref.getContent();
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setFileName('Super Surfaces - Sales Dashboard - '+String.valueOf(DateTime.now())+'.pdf');
        fileAttachment.setContentType('application/pdf');
        fileAttachment.setBody(b);

        email.setSubject('Super Surfaces Sales Dashboard ' + String.valueOf(DateTime.now()));
        email.setToAddresses(emailIDs );
        email.setPlainTextBody('Hi All, Please find attached Super Surfaces Sales Dashboard');
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {fileAttachment});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}
