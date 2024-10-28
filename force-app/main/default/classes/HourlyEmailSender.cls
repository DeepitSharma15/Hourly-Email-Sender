global class HourlyEmailSender implements Schedulable {
    global void execute(SchedulableContext sc) {
        sendHourlyEmail();
    }

    public static void sendHourlyEmail() {
        DateTime oneHourAgo = DateTime.now().addHours(-1);
        
        // Query Accounts with newly created Contacts in the last hour and where IsEmailSent is false
        List<Account> accountsToSend = [
            SELECT Id, Name, Is_Mail_Sent__c, Mail_Send_User__c, 
                    Mail_Send_User__r.Email, Mail_Send_User__r.Name,
                   (SELECT Id, Name, Email FROM Contacts WHERE CreatedDate >= :oneHourAgo)
            FROM Account
            WHERE Is_Mail_Sent__c = false AND Mail_Send_User__c != null
        ];

        if (accountsToSend.isEmpty()) {
            return;
        }

        String emailBody = '<html><body><h3>Dear ' + new String[] {accountsToSend[0].Mail_Send_user__r.Name} + ',</h3><h3>Hey! Hope this Email finds you well, this email is to notify you on newly created contact in the last hour</h3>';
        emailBody += '<table border="1" cellpadding="5" cellspacing="0"><tr><th>Account Name</th><th>Contact Name</th><th>Contact Email</th></tr>';

        // Loop through each Account and its Contacts to populate the table
        for (Account acc : accountsToSend) {
            acc.Is_Mail_Sent__c = true;
            for (Contact con : acc.Contacts) {
                emailBody += '<tr>';
                emailBody += '<td>' + acc.Name + '</td>';
                emailBody += '<td>' + con.Name + '</td>';
                emailBody += '<td>' + con.Email + '</td>';
                emailBody += '</tr>';
            }
        }
        emailBody += '</table></body></html>';

            // Send email to the selected user for this account
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('New Contacts Created in Last Hour ');
            mail.setHtmlBody(emailBody);
            mail.setToAddresses(new String[] { accountsToSend[0].Mail_Send_User__r.Email });

            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            
            //accountsToSend[0].Is_Mail_Sent__c = true;

        // Update accounts to mark email as sent as we have to set Is_Mail_Sent__c to true
        update accountsToSend;
    }
}
