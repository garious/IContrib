var deps = [
    '/tag/tag.js', 
    '/tag/layout1.js', 
    '/ui/core.js', 
    '/ui/nav.js'
];

function onReady(E, L, CORE, NAV) {
    
    function charity(as) {
        as = as || {};
        var user = as.user || defaultUser;
	var box = CORE.box([
            L.spoon([
	        E.div({style: {height: '30px'}}, [CORE.h2(user.firstName)]),
                L.pillow(20),
                L.hug([
                    E.img({style: {width: '175px', height: '175px', borderRadius: '5px'}, src: user.imageUrl, alt: user.firstName}),
                    L.pillow(30),
                    L.spoon([
                        E.p({style: {height: '100', width: '600'}}, user.mission), 
                        L.pillow(20),
                        CORE.button({href: '/me/?donateTo=' + user.id, text: 'Donate!', loud: true})
                    ])
                ])
            ])
        ]);

        return L.spoon([
           L.hug([
                L.pillow(220,0),
                box
           ]),
           L.pillow(30)
        ]);
    }

    function main(params, nodeReady) {
        require([params.cid + '.json'], function(u) {
            nodeReady( NAV.frame([charity({user: u})]) );
        });
    }

    define({
        title: 'IContrib.org',
        main: main
    });

}

require(deps, onReady);

