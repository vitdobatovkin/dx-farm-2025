({
    doInit: function (component, event, helper) {
        let USER_ORGANIZATION_COLUMNS = [
            { label: 'Organization ID', fieldName: 'id', hideDefaultActions: true },
            { label: 'Organization Name', fieldName: 'orgUrl', type: 'url', typeAttributes: { label: { fieldName: 'company' }, target: '_self' }, hideDefaultActions: true },
            { label: 'Parent Organization ID', fieldName: 'parent_organization_id', hideDefaultActions: true },
            { label: 'Roles', fieldName: 'organization_roles', hideDefaultActions: true },
            {
                label: 'Created Time', fieldName: 'create_time', type: "date", hideDefaultActions: true,
                typeAttributes: {
                    year: 'numeric',
                    month: 'numeric',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: true
                }
            },
            {
                label: 'Max Users', fieldName: 'max_users', type: "number", hideDefaultActions: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                type: 'action', typeAttributes: { rowActions: [{ label: 'Create Opportunity', name: 'createOpportunity' }, { label: 'Open in Iris', name: 'openInIris' }] },
                cellAttributes: { menuAlignment: 'left' }
            }
        ];

        component.set('v.columns', USER_ORGANIZATION_COLUMNS);
        helper.setDomain(component);
    },

    handleClose: function (component, event) {
        component.set('v.displayForm', false);
    },

    handleRowLevelAction: function (component, event) {
        let organizationId = event.getParam('rowId');
        component.set('v.organizationId', organizationId);

        if (event.getParam('actionName') === 'createOpportunity') {
            component.set('v.displayForm', true);
            component.find('arUserOrgs').hideModalWindow();
        }else {
            component.find("navigationService").navigate({ 
                type: "standard__webPage", 
                attributes: { 
                    url: `https://iris${component.get("v.subDomain")}.shuttercorp.net/shutterstock/organizations/${organizationId}/overview` 
                } 
            });
        }
    },

    handleCreateNew: function (component, event) {
        component.set('v.displayForm', true);
        component.find('arUserOrgs').hideModalWindow();
    }
});