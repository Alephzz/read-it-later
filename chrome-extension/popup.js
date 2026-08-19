document.addEventListener('DOMContentLoaded', async () => {
  const pageTitle = document.getElementById('pageTitle');
  const pageUrl = document.getElementById('pageUrl');
  const saveBtn = document.getElementById('saveBtn');
  const statusMsg = document.getElementById('statusMsg');
  const tagsInput = document.getElementById('tagsInput');

  // Get current tab info
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

  if (tab && tab.url) {
    pageTitle.textContent = tab.title || 'Untitled';
    pageUrl.textContent = tab.url;
    saveBtn.disabled = false;

    // Check if already saved
    try {
      const port = await getPort();
      const resp = await fetch(`http://localhost:${port}/api/exists?url=${encodeURIComponent(tab.url)}`);
      const data = await resp.json();
      if (data.exists) {
        saveBtn.textContent = '已保存';
        saveBtn.disabled = true;
      }
    } catch (e) {
      // Server not running — still allow save attempt
    }
  } else {
    pageTitle.textContent = '无法获取当前页面';
    pageUrl.textContent = '';
  }

  // Save button
  saveBtn.addEventListener('click', async () => {
    if (!tab || !tab.url) return;

    saveBtn.disabled = true;
    saveBtn.textContent = '保存中...';

    try {
      const port = await getPort();
      const tags = tagsInput.value.split(/[,，;；]/).map(s => s.trim()).filter(Boolean);
      const resp = await fetch(`http://localhost:${port}/api/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: tab.url,
          title: tab.title || tab.url,
          tags
        })
      });

      const data = await resp.json();

      if (data.success) {
        statusMsg.className = 'status success';
        statusMsg.textContent = '已保存 ✓';
        saveBtn.textContent = '已保存';
      } else {
        statusMsg.className = 'status duplicate';
        statusMsg.textContent = data.message || '该链接已存在';
        saveBtn.textContent = '已存在';
      }
    } catch (e) {
      statusMsg.className = 'status error';
      statusMsg.textContent = '连接失败，请确认 Read It Later 应用已启动';
      saveBtn.disabled = false;
      saveBtn.textContent = '重试';
    }
  });
});

// 端口固定为 19623，与 Mac 应用写死的监听端口一致
async function getPort() {
  return 19623;
}
