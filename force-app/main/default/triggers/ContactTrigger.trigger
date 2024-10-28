// It check whether a new contact is created or not if new contact is created then set ismailsent true.
trigger ContactTrigger on Contact (after insert) {
    Set<Id> accountIdsToUpdate = new Set<Id>();

    for (Contact con : Trigger.new) {
        if (con.AccountId != null) {
            accountIdsToUpdate.add(con.AccountId);
        }
    }
    if (!accountIdsToUpdate.isEmpty()) {
        List<Account> accountsToUpdate = [SELECT Id, Is_Mail_Sent__c FROM Account WHERE Id IN :accountIdsToUpdate];
        for (Account acc : accountsToUpdate) {
            acc.Is_Mail_Sent__c = false;
        }
        update accountsToUpdate;
    }
}
