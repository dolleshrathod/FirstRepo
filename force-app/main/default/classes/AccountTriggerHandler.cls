/**
 * Handler class for AccountTrigger
 * Creates an Opportunity when an Account is created
 */
public with sharing class AccountTriggerHandler {
    
    /**
     * Handles after insert operations for Account records
     * Creates an Opportunity for each new Account
     * 
     * @param newAccounts List of newly inserted Account records
     * @param newAccountsMap Map of newly inserted Account records by Id
     * @example
     * AccountTriggerHandler handler = new AccountTriggerHandler();
     * handler.afterInsert(Trigger.new, Trigger.newMap);
     */
    public void afterInsert(List<Account> newAccounts, Map<Id, Account> newAccountsMap) {
        // Validate input
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
        createOpportunitiesForAccounts(newAccounts);
    }
    
    /**
     * Creates an Opportunity for each Account in the provided list
     * 
     * @param accounts List of Account records to create Opportunities for
     */
    private void createOpportunitiesForAccounts(List<Account> accounts) {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
        for (Account acc : accounts) {
            Opportunity opp = new Opportunity(
                Name = acc.Name + ' - Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(30)
            );
            opportunitiesToInsert.add(opp);
        }
        
        // Bulk insert all opportunities with partial success handling
        if (!opportunitiesToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(opportunitiesToInsert, false);
            
            // Log any failures
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMessage = 'Failed to create Opportunity for Account: ' + 
                        accounts[i].Id + '. Errors: ';
                    for (Database.Error err : results[i].getErrors()) {
                        errorMessage += err.getMessage() + '; ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMessage);
                }
            }
        }
    }
}