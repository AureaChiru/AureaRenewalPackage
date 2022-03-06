/*
Organisation: Aurea PvtLtd
Created on: Jan 2022
Description: Helps to send notification to aurea systems to initiate renewal opportunity synchorinization process.
*/
global class SyncAureaRenewalOpportunities{
    
    //is sandbox boolean operator
    global static boolean isSandbox{
        get{
            //is sandbox null check
            if(isSandbox == null){
                //sandbox query check
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            //return organization type
            return isSandbox;
        }
        set{
            //set isSandbox value
            isSandbox = value;
        }
    }
    
    //Aurea Renewals Support custom settings
    global static map<string, AureaRenewal__AureaRenewalsSupport__c> mapAureaRenewals{
        get{
            //check mapAureaRenewals map is null
            if(mapAureaRenewals == null){
                //set values to mapAureaRenewals map from custom settings
                mapAureaRenewals = AureaRenewal__AureaRenewalsSupport__c.getAll();
            }
            //return aurea renewal maps
            return mapAureaRenewals;
        }
        set{
            //set aurea renewals map values
            mapAureaRenewals = value;
        }
    }
    
    //service invocable method to initiate callout operation
    @InvocableMethod(label='Initiate Renewals' description='Renewal opportunity trigger operation')
    global static List<String> initiateRenewals(list<id> AccountIds) {
        //is renewal operation is available to run
        if(mapAureaRenewals.get('Run Renewal Operation').AureaRenewal__Operation_Info__c == 'TRUE'){
            //send renewals notification to aurea systems
            sendNotification(AccountIds);
        }
        return null;
    }
    
    //request body class
    global class restCls{
        //element contains field api name
        global string fieldAPIName;
        //element contains field value
        global string fieldValue;
        
        //inner class constructor with parameters field api name, value
        global restCls(string fieldAPINameVar, string fieldValueVar){
            //field api name to identify the value
            fieldAPIName = fieldAPINameVar;
            //field value related to field api name
            fieldValue = fieldValueVar;
        }
    }
    
    //send email notification to aurea systems
    @Future(callout=true)
    global static void sendNotification(list<id> AccountIds){
                
        //service variables
        Http http;
        HTTPResponse res;
        HttpRequest request;
        
        //fill body elements
        list<restCls> restClsLst = new list<restCls>();
        for(sObject sObj:database.query(mapAureaRenewals.get('Renewals Query Support').AureaRenewal__Operation_Info__c)){
            if(
                mapAureaRenewals.get('Fields To Send').AureaRenewal__Operation_Info__c != '' && 
                mapAureaRenewals.get('Fields To Send').AureaRenewal__Operation_Info__c != null
            ){
                for(string fld:mapAureaRenewals.get('Fields To Send').AureaRenewal__Operation_Info__c.split(',')){
                    restClsLst.add(new restCls(fld, sObj.get(fld)+''));
                }
            }
        }

        //initiate callout request
        http = new Http();
        HttpRequest req = new HttpRequest();
        //set request method
        req.setMethod('GET');
        //set end point
        req.setEndpoint(
            (
                isSandbox ? 
                mapAureaRenewals.get('Sandbox Renewal Site Url').AureaRenewal__Operation_Info__c : 
                mapAureaRenewals.get('Production Renewal Site Url').AureaRenewal__Operation_Info__c
            ) + 
            '?dataCls=' + 
            JSON.serialize(restClsLst)
        );
		//set request header
        req.setHeader('Content-Type', 'application/json');
        //send request
        res = http.send(req);
        
        //logs over the callout
        system.debug('TSI Renewals Response:'+res);
        system.debug('TSI Renewals Response Body:'+res.getBody());
    }
}