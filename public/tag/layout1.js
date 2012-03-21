//
// Layout with hugging and spooning
//

// All combinators are of type "Maybe attrs -> Array a -> a"
//
// hug(  ['a','b','c'])       === 'abc'
// spoon(['a','b','c'])       === 'a\nb\nc'

var deps = [
    'interface.js',
    '2d.js',
    'todom.js'
];

// TODO: Move this into Tag
var Tag_TwoDimensional = {

    // Calculate outer width of a DOM element
    getDimensions: function (me) {
        var sty = me.style;

        var width  = parseInt(sty.width,  10) || 0;
        var height = parseInt(sty.height, 10) || 0;

        width  += parseInt(sty.marginLeft,   10) || 0;
        width  += parseInt(sty.marginRight,  10) || 0;
        height += parseInt(sty.marginTop,    10) || 0;
        height += parseInt(sty.marginBottom, 10) || 0;

        width  += parseInt(sty.paddingLeft,   10) || 0;
        width  += parseInt(sty.paddingRight,  10) || 0;
        height += parseInt(sty.paddingTop,    10) || 0;
        height += parseInt(sty.paddingBottom, 10) || 0;

        width  += parseInt(sty.borderLeftWidth,   10) || 0;
        width  += parseInt(sty.borderRightWidth,  10) || 0;
        height += parseInt(sty.borderTopWidth,    10) || 0;
        height += parseInt(sty.borderBottomWidth, 10) || 0;

        return {
            width:  width,
            height: height
        };
    },

    setPosition: function (me, pos) {
        me.style.position = 'absolute';
        me.style.top = pos.top + 'px';
        me.style.left = pos.left + 'px';
        return me;
    }
    
};

var Tag_ToDom = {
    toDom: function (me) {
        return me;
    },
    getTitle: function (me) {
        return undefined;
    }
};


function onReady(I, DIM, DOM) {

    // a TwoDimensional instance for the Pillow class
    var Pillow_TwoDimensional = {
        getDimensions: function (me) {
            return {
                width: me.width,
                height: me.height
            };
        },

        setPosition: function (me, pos) {
            return me;
        }
    };
    
    // a TwoDimensional instance for the Party class
    var Party_TwoDimensional = Pillow_TwoDimensional;
    
    // a ToDom instance for the Party class
    var Party_ToDom = {
        toDom: function (me) {
            var div = document.createElement('div');
            div.style.height = me.height + 'px';
            div.style.width = me.width + 'px';
            div.style.position = 'absolute';
    
            // ys = filter (!= pillow) xs
            var xs = me.subelements;
            for (var i = 0; i < xs.length; i += 1) {
                var x = xs[i];
                var iface = I.getInterface(x, DOM.ToDom) || Tag_ToDom;
                x = iface && iface.toDom(x) || x;
                if (x.constructor !== pillow) {  // Since DOM elements to not implement ToDom, we unfortunately have to pull pillows explicitly.
                    div.appendChild(x);
                }
            }
            return div;
        },
        getTitle: function (me) {
            return undefined;
        }
    };
    
    // pillow(w, h)
    //
    //     Create empty space of 'w' pixels wide and 'h' pixels tall.  Pillow elements 
    //     are not added to the DOM, and are only used for managing space.
    function pillow(w, h) {
        if (h === undefined) {
            h = w;
        }
        return {
            constructor: pillow,
            width: w,
            height: h 
        };
    }
    
    pillow.interfaces = [
        {'interface': DIM.TwoDimensional, instance: Pillow_TwoDimensional}
    ];
    
    // party(attrs, subelements)
    //
    //    a placeholder for visual elements to snuggle
    function party(as, xs) {
    
        return {
            constructor: party,
            width: as.width,
            height: as.height,
            subelements: xs
        };
    }
    
    party.interfaces = [
        {'interface': DOM.ToDom,          instance: Party_ToDom},
        {'interface': DIM.TwoDimensional, instance: Party_TwoDimensional}
    ];
    
    // Concatenate elements
    function cat(as, xs, setPos) {
    
        // dim = reduce(setPos, xs, (0,0))
        var dim = {width: 0, height: 0};
        for (var i = 0; i < xs.length; i += 1) {
            var x = xs[i];
            dim = setPos(x, dim);
        }
    
        return party(dim, xs);
    }
    
    // Set the horizontal position of a 2D element
    function setHPos(x, dim) {
        var iface = I.getInterface(x, DIM.TwoDimensional) || Tag_TwoDimensional;
        iface.setPosition(x, {'top': 0, left: dim.width});
    
        var d = iface.getDimensions(x);
        return {
            width: dim.width + d.width,
            height: d.height > dim.height ? d.height : dim.height
        };
    }
    
    // Concatenate elements horizontally
    function hcat(as, xs) {
        if (as && as.constructor === Array) {
            xs = as;
            as = null;
        }
        return cat(as, xs, setHPos);
    }
    
    // Set the vertical position of a 2D element
    function setVPos(x, dim) {
        var iface = I.getInterface(x, DIM.TwoDimensional) || Tag_TwoDimensional;
        iface.setPosition(x, {'top': dim.height, left: 0});

        var d = iface.getDimensions(x);
        return {
            height: dim.height + d.height,
            width: d.width > dim.width ? d.width : dim.width
        };
    }
    
    // Concatenate elements vertically
    function vcat(as, xs) {
        if (as && as.constructor === Array) {
            xs = as;
            as = null;
        }
        return cat(as, xs, setVPos);
    }
    
    // Concatenate elements horizontally and wrap in a DOM element
    function hug(as, xs) {
        var b = hcat(as, xs);
        var iface = I.getInterface(b, DOM.ToDom);
        return iface.toDom(b);
    }
    
    // Concatenate elements vertically and wrap in a DOM element
    function spoon(as, xs) {
        var b = vcat(as, xs);
        var iface = I.getInterface(b, DOM.ToDom);
        return iface.toDom(b);
    }
    
    define({
        hcat:   hcat,
        vcat:   vcat,
        hug:    hug,
        spoon:  spoon,
        pillow: pillow
    });
}

require(deps, onReady);

