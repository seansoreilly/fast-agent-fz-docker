// == Auto-Allow MCP Tools in Claude Desktop Client ==
//
// HOW TO USE:
// 1. Open Claude Desktop client
// 2. Go to: Help → Enable Developer Mode
// 3. Press Ctrl+Shift+Alt+I (Windows) or Cmd+Opt+Shift+I (Mac) to open Developer Tools
// 4. Type `allow pasting` in the console and hit Enter
// 5. Paste this entire script and press Enter
//    It will auto-approve any tool request with 'Allow for this chat'
// 6. NOTE: You must repeat this on each restart of Claude Desktop

let lastClickTime = 0;
const COOLDOWN_MS = 2000; // 2 seconds cooldown

const observer = new MutationObserver(() => {
  const now = Date.now();
  if (now - lastClickTime < COOLDOWN_MS) {
    console.log("🕒 Still in cooldown period, skipping...");
    return;
  }

  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) return;

  const buttonWithDiv = dialog.querySelector("button div");
  if (!buttonWithDiv) return;

  const toolText = buttonWithDiv.textContent;
  if (!toolText) return;

  console.log("📝 Found tool request:", toolText);

  const toolName = toolText.match(/Run (\S+) from/)?.[1];
  if (!toolName) return;

  console.log("🛠️ Tool name:", toolName);

  const allowButton = Array.from(dialog.querySelectorAll("button")).find(
    (button) => button.textContent.toLowerCase().includes("allow for this chat")
  );

  if (allowButton) {
    console.log("🚀 Auto-approving tool:", toolName);
    lastClickTime = now;
    allowButton.click();
  }
});

observer.observe(document.body, { childList: true, subtree: true });
