document.addEventListener('DOMContentLoaded', () => {
  const portInput = document.getElementById('port');
  const saveBtn = document.getElementById('saveBtn');
  const savedMsg = document.getElementById('savedMsg');

  // Load saved settings
  chrome.storage.local.get(['port'], (result) => {
    if (result.port) {
      portInput.value = result.port;
    }
  });

  saveBtn.addEventListener('click', () => {
    const port = parseInt(portInput.value, 10);
    if (port < 1024 || port > 65535) {
      alert('端口号必须在 1024-65535 之间');
      return;
    }

    chrome.storage.local.set({ port }, () => {
      savedMsg.style.display = 'inline';
      setTimeout(() => { savedMsg.style.display = 'none'; }, 2000);
    });
  });
});
