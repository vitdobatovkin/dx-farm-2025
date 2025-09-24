({
	getOpportunityInstance : function(component, event, helper) {
		var oppId = component.get("v.recordId");
        var action = component.get("c.fetchOpportunity");
        var urlRedirect = '';
        action.setParams({
            oppId: oppId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                var oppInstance = response.getReturnValue();
                if(oppInstance.Commitment_Type__c == 'Portfolio Subscription' && oppInstance.Commitment_Type__c == 'Upfront Commitment' && oppInstance.Portfolio_Package__c  == 'Custom Deal'
                   && oppInstance.RecordType.Name == 'Premier Pre-Paid Opportunity'){
                    urlRedirect = '/apex/VF_opportunityProductEntry?id='  + oppInstance.Id;
                }
				else if(oppInstance.RecordTypeName_ENT__c.includes("Premier") || oppInstance.RecordType.Name == 'Shutterstock - Customer - Inside Sales' || oppInstance.RecordTypeName_ENT__c.includes("Commercial_Use_Opportunity")) {
                    urlRedirect='/apex/opportunityProductEntry?id=' + oppInstance.Id;
                }
                else if(oppInstance.RecordType.Name == 'Exclusive Opportunity') { 
                    urlRedirect='/apex/opportunityProductEntry_Exclusive?id=' + oppInstance.Id; 
                }
                else if(oppInstance.RecordType.Name == 'Pond5 Opportunity' ||
                oppInstance.RecordType.Name == 'Pond5 Commercial Use' ||
                oppInstance.RecordType.Name == 'Studios' || 
                oppInstance.RecordType.Name == 'Platform Solutions') { 
                    urlRedirect='/apex/quickQuotePage?oId='+oppInstance.Id+'&aId='+oppInstance.AccountId;
                } 
                else { 
                    urlRedirect='/apex/opportunityProductEntry?id=' + oppInstance.Id;
                }
                
                var eUrl= $A.get("e.force:navigateToURL");
                eUrl.setParams({
                    "url": urlRedirect
                });
                eUrl.fire();
            }
            else{
                alert('There was an error processing you request. Please inform System Administrator.');
            }
        });
        
        $A.enqueueAction(action);
	}
})