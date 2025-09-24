({
    setDomain: function (component) {
        let subDomain = '';
        let url = window.location.href;
        if(url.includes('dev')) {
            subDomain = '.dev';
        }else if(url.includes('qa')) {
            subDomain = '.q123123a';
        }
        component.set('v.subDomain', subDomain);
    },
})