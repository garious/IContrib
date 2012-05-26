var deps = [
    '/Tag/Tag.js', 
    '/Tag/Layout.js',
    '/Skin/Chart.js', 
    '/Skin/Colors.js', 
    '/Skin/Core.js'
];

function onReady(Tag, Layout, Chart, Colors, Core) {

    function alignButton(user) {
        return Core.button({href: '/Me?donateTo=' + user.id, loud: true, text: 'Donate!'});
    }

    function isMember(xs, x) {
        for (var i = 0; i < xs.length; i++) {
            if ( xs[i] === x ) {
                return true;
            }
        }
        return false;
    }

    function fundContents(xs, total, colors) {
        var rows = [Layout.pillow(0, 15)];

        for (var j = 0; j < xs.length; j++) {
            var x = xs[j];
            var pct = Core.h6(Math.round(1000 * x.shares / total) / 10 + '%');


            var cols = Layout.hug([
                Tag.tag({
                    name: 'div',
                    style: {width: '18px', height: '18px', backgroundColor: colors[j % colors.length]}
                }),
                Layout.pillow(15, 0),
                Tag.tag({
                    name: 'div',
                    style: {width: '55px', height: pct.height},
                    contents: [pct]
                }),
                Core.hyperlink({url: 'Charity?id=' + x.cid, text: x.name})
            ]);
            rows.push(cols);
        }
        return Layout.spoon(rows);
    }

    function distributionTable(dist) {
        // inplace sort.  TODO: Probably should clone the array
        dist.sort(function(a,b){return b.shares - a.shares;});

        var total = 0;
        for (var j = 0; j < dist.length; j++) {
            var d = dist[j];
            total += d.shares;
        }

        var colors = Colors.dashboardColors;

        var row = Tag.tag({
            name: 'div',
            style: {width: '100%'},
            contents: [
                Layout.hug([
                    fundContents(dist, total, colors),
                    Layout.pillow(20, 0),
                    Chart.pieSnapshot({distribution: dist, colors: colors, height: 200})
                ])
            ]
        });

        return row;
    }

    function profile(as) {
        as = as || {};
        var user = as.user || {};
        var name = user.firstName + ' ' + user.lastName;
        var userInfo = Layout.hug([
            Layout.pillow(25, 0), 
            Core.h3(name)
        ]);

        return Layout.spoon([
            Layout.hug([
                Tag.tag({
                    name: 'img',
                    style: {width: '90px', height: '90px'},
                    attributes: {src: user.imageUrl, alt: name}
                }),
	        userInfo
            ]),
            Layout.pillow(0, 10),
            distributionTable(user.distribution)
        ]);
    }

    function recommendedFunds(as) {

        var width = as.width || 340;

        var listItems = [
            Core.h5({
                color: Colors.greenText,
                text: 'Recommended Funds'
            })
        ];

        for (var i = 0; i < as.funds.length; i += 1) {
            var x = as.funds[i];
            listItems.push( Layout.pillow(0, 10) );
            listItems.push( Core.hr({width: width - 4, marginLeft: -15}) );
            listItems.push( Layout.pillow(0, 10) );

            var e = Layout.hug([
                Tag.tag({
                    name: 'img',
                    attributes: {src: x.imageUrl},
                    style: {width: '50px', height: '50px'}
                }),
                Layout.pillow(20, 0),
                Core.hyperlink({url: '/Charity?id=' + x.cid, text: x.name})
            ]);

            listItems.push(e);
        }

        return Core.box({
            width: width,
            contents: Layout.spoon(listItems)
        });
    }

    Yoink.define({
        profile: profile,
        recommendedFunds: recommendedFunds,
        alignButton: alignButton
    });
}

Yoink.require(deps, onReady);

