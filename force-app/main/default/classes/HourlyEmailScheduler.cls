global class HourlyEmailScheduler implements Schedulable{
    global void execute(SchedulableContext SC) {
        AccountContactBatch batch = new AccountContactBatch();
        Database.executeBatch(batch);
    }
}