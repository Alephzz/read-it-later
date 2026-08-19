// Background service worker for close-tab detection (P2 feature)
// Currently a placeholder — will be implemented in Phase 3

// Listen for tab removal
chrome.tabs.onRemoved.addListener(async (tabId, removeInfo) => {
  // This is P2 — close-tab notification
  // Will be implemented later
});

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'saveUrl') {
    saveUrl(request.url, request.title)
      .then(result => sendResponse(result))
      .catch(err => sendResponse({ success: false, message: err.message }));
    return true; // async response
  }
});

async function saveUrl(url, title) {
  // 端口固定为 19623，与 Mac 应用写死的监听端口一致
  const port = 19623;

  const resp = await fetch(`http://localhost:${port}/api/save`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ url, title })
  });

  return resp.json();
}
