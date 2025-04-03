const originalFetch = window.fetch;
window.fetch = async function(input, init) {
    if (typeof input === 'string') {
        input = privateRelayURL(input);
    } else if (input instanceof Request) {
        input = new Request(privateRelayURL(input.url), input);
    }
    return originalFetch.call(this, input, init);
};
const originalOpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
    url = privateRelayURL(url);
    return originalOpen.apply(this, arguments);
};
function privateRelayURL(url) {
    if (!url.startsWith("https://privacy-relay.darock.top/proxy/")) {
        if (url.startsWith("https://privacy-relay.darock.top/")) {
            return "https://privacy-relay.darock.top/proxy/" + extractTargetOrigin(window.location) + url.slice(32)
        } else {
            return "https://privacy-relay.darock.top/proxy/" + url
        }
    } else {
        return url
    }
}
function updateResourceURLs() {
    document.querySelectorAll('img, script, link, video, audio, iframe').forEach(el => {
        if (el.src) {
            el.src = privateRelayURL(el.src);
        }
        if (el.href) {
            el.href = privateRelayURL(el.href);
        }
    });
}
updateResourceURLs();
new MutationObserver(mutations => {
    mutations.forEach(mutation => {
        mutation.addedNodes.forEach(node => {
            if (node.tagName) {
                if (['IMG', 'SCRIPT', 'LINK', 'VIDEO', 'AUDIO', 'IFRAME'].includes(node.tagName)) {
                    if (node.src) node.src = privateRelayURL(node.src);
                    if (node.href) node.href = privateRelayURL(node.href);
                }
            }
        });
    });
}).observe(document.documentElement, { childList: true, subtree: true });
function extractTargetOrigin(url) {
    try {
        const parsedUrl = new URL(url);
        const path = parsedUrl.pathname;
        const proxyPrefix = "/proxy/";
        if (path.startsWith(proxyPrefix)) {
            const targetUrl = path.substring(proxyPrefix.length);
            const targetParsed = new URL(decodeURIComponent(targetUrl));
            return targetParsed.origin;
        }
    } catch (e) {
        console.error("Invalid URL:", e);
    }
    return null;
}
