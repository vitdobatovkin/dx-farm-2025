({
    doInit: function (component, event, helper) {
        let ORGANIZATION_TEAM_MEMBERS_COLUMNS = [
            { label: 'Account Service ID', fieldName: 'id', hideDefaultActions: true},
            { label: 'User Name', fieldName: 'userUrl', type: 'url', typeAttributes: {label: {fieldName: 'username'}, target: '_self'}, hideDefaultActions: true},
            { label: 'Full Name', fieldName: 'fullName', hideDefaultActions: true},
            { label: 'Email', fieldName: 'email', type: 'email', hideDefaultActions: true},
            { label: 'Language', fieldName: 'language', hideDefaultActions: true},
            { label: 'Roles', fieldName: 'roles', hideDefaultActions: true},
            { label: 'Is Disabled', fieldName: 'isDisabled', type:'boolean', hideDefaultActions: true},
            {
                type: 'action', typeAttributes: { rowActions: [{ label: 'Create Opportunity', name: 'createOpportunity' }, { label: 'Open in Iris', name: 'openInIris' }] },
                cellAttributes: { menuAlignment: 'left' }
            }
        ];

        component.set('v.columns', ORGANIZATION_TEAM_MEMBERS_COLUMNS);
        helper.setDomain(component);
    },

    handleClose: function (component, event) {
        component.set('v.displayForm', false);
    },

    handleRowLevelAction: function (component, event) {
        let userId = event.getParam('rowId');
        component.set('v.userId', userId);

        if (event.getParam('actionName') === 'createOpportunity') {
            component.set('v.displayForm', true);
            component.find('arOrgTeamMembers').hideModalWindow();
        }else {
            component.find("navigationService").navigate({ 
                type: "standard__webPage", 
                attributes: { 
                    url: `https://iris${component.get("v.subDomain")}.shuttercorp.net/shutterstock/users/${userId}/overview` 
                } 
            });
        }
    },

    handleCreateNew: function (component, event) {
        component.set('v.displayForm', true);
        component.find('arOrgTeamMembers').hideModalWindow();
    }
});