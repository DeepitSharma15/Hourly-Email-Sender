global class AccountContactBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime oneHourAgo = DateTime.now().addHours(-1);
        
        // Query Accounts with newly created Contacts in the last hour and where IsEmailSent is false
        return Database.getQueryLocator([
            SELECT Id, Name, Is_Mail_Sent__c, Mail_Send_User__c, 
                   Mail_Send_User__r.Email, Mail_Send_User__r.Name,
                   (SELECT Id, Name, Email FROM Contacts WHERE CreatedDate >= :oneHourAgo)
            FROM Account
            WHERE Is_Mail_Sent__c = false AND Mail_Send_User__c != null
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        if (scope.isEmpty()) {
            return;
        }

        // Email body 
        String emailBody = '<html><body>';
        emailBody += '<h3>Dear ' + scope[0].Mail_Send_User__r.Name + ',</h3>';
        emailBody += '<h3>Hey! Hope this Email finds you well. This email is to notify you of newly created contacts in the last hour:</h3>';
        emailBody += '<table border="1" cellpadding="5" cellspacing="0"><tr><th>Account Name</th><th>Contact Name</th><th>Contact Email</th></tr>';

        for (Account acc : scope) {
            if (acc.Contacts.size() > 0) {
                
                for (Contact con : acc.Contacts) {
                    emailBody += '<tr>';
                    emailBody += '<td>' + acc.Name + '</td>';
                    emailBody += '<td>' + con.Name + '</td>';
                    emailBody += '<td>' + con.Email + '</td>';
                    emailBody += '</tr>';
                }
                acc.Is_Mail_Sent__c = true;
                
            }
        }
        emailBody += '</table></body></html>';
        // Send email to the selected user for this account
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('New Contacts Created in Last Hour');
        mail.setHtmlBody(emailBody);
        mail.setToAddresses(new String[] { scope[0].Mail_Send_User__r.Email });

        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 
        // Update accounts to mark email as sent and update is mail sent in account
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: You can add post-processing logic here, if needed
    }
}
