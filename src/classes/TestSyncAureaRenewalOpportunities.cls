@isTest(SeeAllData=false)
public with sharing class TestSyncAureaRenewalOpportunities {
    
    //setup test data
    static testMethod void initiateRenewals() {
        test.startTest();
        list<AureaRenewal__AureaRenewalsSupport__c > csRec = new list<AureaRenewal__AureaRenewalsSupport__c >();
        csRec.add(
            new AureaRenewal__AureaRenewalsSupport__c (
                name='Fields To Send', 
                AureaRenewal__Operation_Info__c = 'Id,NetSuite_ID__c'
            )
        );
        csRec.add(
            new AureaRenewal__AureaRenewalsSupport__c (
                name='Production Renewal Site Url', 
                AureaRenewal__Operation_Info__c = 'https://aurea.secure.force.com/services/apexrest/TSISupport'
            )
        );
        csRec.add(
            new AureaRenewal__AureaRenewalsSupport__c (
                name='Renewals Query Support', 
                AureaRenewal__Operation_Info__c = 'select Id,NetSuite_ID__c,Name from account where Id IN : AccountIds'
            )
        );
        csRec.add(
            new AureaRenewal__AureaRenewalsSupport__c (
                name='Run Renewal Operation', 
                AureaRenewal__Operation_Info__c = 'TRUE'
            )
        );
        csRec.add(
            new AureaRenewal__AureaRenewalsSupport__c (
                name='Sandbox Renewal Site Url', 
                AureaRenewal__Operation_Info__c = 'https://sfdev-aurea.cs203.force.com/services/apexrest/TSISupport'
            )
        );
        insert csRec;
        
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        //Opportunity without Type and without NetSuiteId, should not create if validation rules are active
        Opportunity opp = new Opportunity(
            Name = 'Opportunity',
            StageName = 'Pending',
            CloseDate = System.today().addMonths(1),
            AccountId = acct.Id
        );
        insert opp;
        
        // Set mock callout class 
        RenewalsMockHttpResponseGenerator mockHttp = new RenewalsMockHttpResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mockHttp);
        
        //trigger opportunity flow
        update opp;
        
        //initiate outbound calls
        SyncAureaRenewalOpportunities.initiateRenewals(new list<id>{acct.id});
        
        //set mapAureaRenewals map values
        SyncAureaRenewalOpportunities.mapAureaRenewals = SyncAureaRenewalOpportunities.mapAureaRenewals;
        
        //set organization type values true/false
        SyncAureaRenewalOpportunities.isSandbox = (SyncAureaRenewalOpportunities.isSandbox ? false : true);
        
        //initiate outbound calls
        SyncAureaRenewalOpportunities.initiateRenewals(new list<id>{acct.id});
        test.stopTest();
    }    
    
}