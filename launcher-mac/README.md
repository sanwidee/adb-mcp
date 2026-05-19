# Photoshop + Claude — Mac Launcher

> **This launcher wraps [mikechambers/adb-mcp](https://github.com/mikechambers/adb-mcp).**
> The MCP server, Node proxy, and UXP plugin are entirely Mike Chambers' work.
> What's in this folder is just the on-ramp: an installer + daily launcher
> + an Indonesian-language guide intended for non-technical design teams.

---

# Photoshop + Claude — Design Team Setup

This lets you tell Claude (in plain English) what to do to a Photoshop file,
and it edits the file for you — keeping all the layers intact.

> Example: *"Resize this 1080×1080 post to a 1080×1920 story and keep the
> headline centered."*

You only do the **Setup** part once per Mac. After that, just **double-click
`StartSession.command`** before each work session.

---

## Before you start

You need:

- A Mac (macOS 12 Monterey or newer)
- ~5 GB free disk space
- Internet connection
- **Adobe Photoshop 2025 (version 26.0)** or newer
- **Claude Desktop** installed (https://claude.ai/download)

You do **not** need to install Homebrew, Python, Node, or Xcode yourself
— the installer takes care of all of that. If your Mac has never built
software before, the installer will trigger a one-time **Xcode Command
Line Tools** download (~1.5 GB, 10–25 min). A system popup will appear
asking permission — click **"Install"** (NOT "Get Xcode"). The installer
waits automatically while this finishes.

Ask IT if Photoshop or Claude Desktop are missing.

---

## Setup (one time only — ~10 minutes)

### 1. Open Terminal

Press `Cmd + Space`, type **Terminal**, and hit Return.

### 2. Run the installer

In the Terminal window, type this and press Return:

```
bash "/Volumes/Sanwidi 2TB/02-projects/Pintarnya/adobe-mcp /install_setup.sh"
```

> If your copy lives somewhere else, drag the `install_setup.sh` file from
> Finder into Terminal — it will paste the correct path.

You may be asked for your Mac password (this is so Homebrew can install
things). Type it and press Return. **You won't see the characters as you
type** — that's normal.

The script will install everything it needs and print a green
"Automated setup complete" message at the end.

### 3. Install the UXP Developer Tool

This is the bridge between Photoshop and Claude.

1. Go to
   https://developer.adobe.com/photoshop/uxp/2022/guides/devtool/
2. Download and install **UXP Developer Tool** (UDT). It installs like any
   normal app.

### 4. Load the Claude plugin into Photoshop

1. **Open Photoshop** first.
2. **Open the UXP Developer Tool** (UDT).
3. Click **"Add Plugin..."** (top right corner).
4. Navigate to and select this file:
   ```
   ~/tools/adb-mcp/uxp/ps/manifest.json
   ```
   *(In Finder, press `Cmd + Shift + G` and paste that path.)*
5. In UDT, find the row that just appeared. Click the **•••** menu on the
   right → **Load**.
6. Back in Photoshop, you should now see a small **"Claude"** panel.
   *(If you don't see it: Photoshop menu → Window → Plugins → Claude.)*

You're done with setup! You won't need to repeat any of this.

---

## Daily use

### Start a session

1. Open Finder and go to the folder with `StartSession.command`.
2. **Double-click `StartSession.command`.**
   - A Terminal window opens and shows
     `✅ Ready. Open Photoshop + Claude Desktop.`
   - **Keep this window open.** Closing it ends the session.

> **First time only:** macOS may say *"`StartSession.command` cannot be
> opened because it is from an unidentified developer."* Right-click the
> file → **Open** → **Open**. After this, double-clicking works normally.

### Connect Photoshop

1. Open Photoshop if it's not already open.
2. In the **Claude** plugin panel inside Photoshop, click **Connect**.
   - Status should turn to **Connected**.

### Talk to Claude

1. Open **Claude Desktop**.
2. Open the file you want to work on in Photoshop.
3. In Claude, just describe what you want. For example:
   - *"Open the file at ~/Desktop/banner.psd and tell me what layers it has."*
   - *"Resize this design to 1080×1920 and keep the logo top-left."*
   - *"Duplicate the page and change the headline to 'Lebaran Sale'."*

Claude will do the edits in Photoshop. Watch it happen live.

### End the session

When you're done, click the Terminal window that's running
`StartSession.command` and press **Ctrl + C**. You'll see *"All processes
stopped. Goodbye."* — you can now close the window.

---

## If something stops working

| Problem | What to try |
| --- | --- |
| Claude Desktop doesn't list "photoshop" | Quit Claude Desktop fully (`Cmd + Q`) and reopen. |
| UXP plugin says **Disconnected** | Make sure `StartSession.command` is still running. Click **Connect** again. |
| Started a new session and panel won't connect | Quit Photoshop, restart `StartSession.command`, then reopen Photoshop and click **Connect**. |
| Nothing works | Re-run `install_setup.sh`. It's safe to run more than once. |

For anything else, message **#design-tools** on Slack.

---

## What's actually running?

Two small helpers run in the background while `StartSession.command` is
open:

- A **Node proxy** that the UXP plugin connects to.
- A **Python MCP server** that Claude Desktop launches on its own.

You don't need to think about either — just keep the Terminal window open.
