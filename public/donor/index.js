var deps = [
    '/tag/tag.js', 
    '/tag/layout1.js',
    '/ui/nav.js', 
    '/ui/chart.js', 
    '/ui/core.js'
];

function onReady(E, L, NAV, CHART, CORE) {

    function alignButton(user) {
        return CORE.button({href: '/me/?donateTo=' + user.id, loud: true, text: 'Donate!'});
    }

    function isMember(xs, x) {
        for (var i = 0; i < xs.length; i++) {
            if ( xs[i] === x ) {
                return true;
            }
        }
        return false;
    }

    function fundContents(xs, total) {
        var rows = [];

        for (var j = 0; j < xs.length; j++) {
            var x = xs[j];
            var pct = CORE.h6(Math.round(1000 * x.shares / total) / 10 + '%');

            var cols = L.hug([
                E.div({style: {width: '70px', height: pct.height}}, [pct]),
                CORE.a({href: 'charity/?id=' + x.cid}, x.name)
            ]);
            rows.push(cols);
        }
        return L.spoon(rows);
    }

    function distributionTable(user) {
        if (user.funds) {
            var rows = [];
            var dist = user.distribution;
            for (var i = 0; i < user.funds.length; i++) {

                var fundId = user.funds[i].labels[0];  // TODO: Anatoly, why is this a list?
                var xs = [];
                var total = 0;

                // filter (nm `elem` dist.labels)
                for (var j = 0; j < dist.length; j++) {
                    if (isMember(dist[j].labels, fundId)) {
                        var d = dist[j];
                        total = total + d.shares;
                        xs.push(d);
                    }
                }

                var row = L.spoon([
                    E.hr({style: {height: '1px', width: '570px'}}),
                    L.pillow(0, 20),
                    E.div({style: {height: '30px'}}, [
                        CORE.h4(user.funds[i].name),
                        E.div({style: {position: 'absolute', top: '10px', left: '505px'}}, [  // TODO: remove top 10px, which is due to the button falling outside its bounds
                            alignButton({id: fundId})
                        ])
                    ]),
                    L.hug([
                        CHART.pie1({distribution: xs}),  // TODO: display chart filtered by label
                        fundContents(xs, total)
                    ])
                ]);

                rows.push(row);
            }
            return L.spoon(rows);
        }
    }

    function profile(as) {
        as = as || {};
        var user = as.user || {};
        var userInfo = L.hug([
            L.pillow(25, 0), 
            L.spoon([
                CORE.h3(user.firstName + ' ' + user.lastName),
                E.span({style: {color: 'red'}}, [
                    CORE.h5('Helps raise $' + Math.round(user.alignedDonated / 100) + ' per month')
                ])
            ])
        ]);

        return L.spoon([
            L.hug([
                E.img({style: {width: '70px', height: '90px'}, src: user.imageUrl, alt: user.firstName + ' ' + user.lastName}),
	        userInfo
            ]),
            L.pillow(0, 20),
            distributionTable(user)
        ]);
    }

    define({
        profile: profile,
        alignButton: alignButton
    });
}

require(deps, onReady);

