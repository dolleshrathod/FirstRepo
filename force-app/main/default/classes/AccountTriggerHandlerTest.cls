/**
 * Test class for AccountTriggerHandler
 * Tests the creation of Opportunities when Accounts are created
 */
@isTest
private class AccountTriggerHandlerTest {
    
    // Test Class
    @TestSetup
    static void setupTestData() {
        // Create test accounts but do not insert yet
        // The trigger will be tested during insert
    }
    
    /**
     * Test that a single Opportunity is created when a single Account is inserted
     */
    @isTest
    static void shouldCreateOpportunity_WhenSingleAccountInserted() {
        // Given
        Account acc = TestDataFactory.createAccount(false);
        acc.Name = 'Single Test Account';
        
        // When
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Then
        List<Opportunity> opps = [
            SELECT Id, Name, AccountId, StageName, CloseDate
            FROM Opportunity
            WHERE AccountId = :acc.Id
        ];
        
        Assert.areEqual(1, opps.size(), 'Exactly one Opportunity should be created');
        Assert.areEqual('Single Test Account - Opportunity', opps[0].Name, 
            'Opportunity name should match Account name with suffix');
        Assert.areEqual(acc.Id, opps[0].AccountId, 
            'Opportunity should be related to the Account');
        Assert.areEqual('Prospecting', opps[0].StageName, 
            'Opportunity stage should be Prospecting');
        Assert.areEqual(System.today().addDays(30), opps[0].CloseDate, 
            'Opportunity close date should be 30 days from today');
    }
    
    /**
     * Test bulk insert with 251 Accounts to verify bulkification
     * Tests beyond the 200-record trigger batch boundary
     */
    @isTest
    static void shouldCreateOpportunities_WhenBulkAccountsInserted() {
        // Given
        Integer accountCount = 251;
        List<Account> accounts = TestDataFactory.createAccounts(accountCount, false);
        
        // When
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Then
        List<Opportunity> opps = [
            SELECT Id, AccountId, StageName
            FROM Opportunity
            WHERE AccountId IN :accounts
        ];
        
        Assert.areEqual(accountCount, opps.size(), 
            'Should create one Opportunity per Account for all 251 accounts');
        
        // Verify all opportunities have correct stage
        for (Opportunity opp : opps) {
            Assert.areEqual('Prospecting', opp.StageName, 
                'All opportunities should have Prospecting stage');
        }
        
        // Verify each account has exactly one opportunity
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            Assert.isFalse(accountIds.contains(opp.AccountId), 
                'Each Account should have exactly one Opportunity');
            accountIds.add(opp.AccountId);
        }
    }
    
    /**
     * Test that handler gracefully handles null input
     */
    @isTest
    static void shouldHandleGracefully_WhenNullAccountList() {
        // Given
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        // When
        Test.startTest();
        handler.afterInsert(null, null);
        Test.stopTest();
        
        // Then - no exceptions should be thrown
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        Assert.areEqual(0, opps.size(), 'No opportunities should be created for null input');
    }
    
    /**
     * Test that handler gracefully handles empty account list
     */
    @isTest
    static void shouldHandleGracefully_WhenEmptyAccountList() {
        // Given
        AccountTriggerHandler handler = new AccountTriggerHandler();
        List<Account> emptyList = new List<Account>();
        Map<Id, Account> emptyMap = new Map<Id, Account>();
        
        // When
        Test.startTest();
        handler.afterInsert(emptyList, emptyMap);
        Test.stopTest();
        
        // Then - no exceptions should be thrown
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        Assert.areEqual(0, opps.size(), 'No opportunities should be created for empty list');
    }
    
    /**
     * Test that Opportunities are created with correct field values
     */
    @isTest
    static void shouldSetCorrectFields_WhenOpportunityCreated() {
        // Given
        Account acc = new Account(
            Name = 'Test Account with Special Name'
        );
        
        // When
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Then
        Opportunity opp = [
            SELECT Id, Name, AccountId, StageName, CloseDate
            FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];
        
        Assert.isNotNull(opp, 'Opportunity should be created');
        Assert.areEqual('Test Account with Special Name - Opportunity', opp.Name, 
            'Opportunity name should be derived from Account name');
        Assert.areEqual(acc.Id, opp.AccountId, 
            'AccountId should be set correctly');
        Assert.areEqual('Prospecting', opp.StageName, 
            'Stage should be set to Prospecting');
        
        Date expectedCloseDate = System.today().addDays(30);
        Assert.areEqual(expectedCloseDate, opp.CloseDate, 
            'Close date should be 30 days from insertion date');
    }
}