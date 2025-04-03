const allElements = document.querySelectorAll('*');
function applyDarkMode(element) {
    element.style.backgroundColor = '#121212';
    element.style.color = '#ffffff';
}
allElements.forEach(applyDarkMode);
const observer = new MutationObserver(mutations => {
    mutations.forEach(mutation => {
        if (mutation.type === 'childList') {
            mutation.addedNodes.forEach(node => {
                if (node.nodeType === Node.ELEMENT_NODE) {
                    applyDarkMode(node);
                    node.querySelectorAll('*').forEach(applyDarkMode);
                }
            });
        }
    });
});
observer.observe(document.documentElement, { childList: true, subtree: true });
