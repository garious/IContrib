// Create a DOM element from a name, attributes object, and array of children.

function text(s) {
    return document.createTextNode(s);
}

function tag(nm, as, xs) {
    if (as && as.constructor === Array) {
        xs = as;
        as = null;
    }

    var e = document.createElement(nm); 
    if (as) {
        for (var k in as) {
            if (k === 'style') {
                var style = as[k];
                for (var s in style) {
                    e.style[s] = style[s];
                }
            } else {
                e.setAttribute(k, as[k]);
            }
        }
    }
    if (xs) {
        for (var i = 0; i < xs.length; i++) {
            var x = xs[i];
            if (typeof x === 'string') {
               x = text(x);
            }
            e.appendChild(x);
        }
    }
    return e;
}

function mkTag(nm) {
    return function(as, xs) {
        return tag(nm, as, xs);
    };
}

var TAG = {
    tag:        tag,
    mkTag:      mkTag,
    text:       text
};

var tags = ['br', 'p', 'div', 'link', 'a', 'img', 'form', 'input', 'h1', 'h2', 'h3', 'h4', 'base', 'ul', 'ol', 'li'];

for (var i = 0; i < tags.length; i++) {
    var nm = tags[i];
    TAG[nm] = mkTag(nm);
}

return TAG;

