public class UpdateContactLastCheckedQueueable implements Queueable {

    public void execute(QueueableContext context) {
        // Fetch contacts to update (LIMIT used for sandbox safety)
        List<Contact> contacts = [SELECT Id, Last_Checked__c FROM Contact LIMIT 100];

        for (Contact con : contacts) {
            con.Last_Checked__c	 = Date.today();
        }

        update contacts;
    }
}