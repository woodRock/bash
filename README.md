# Game Design Document: Bash

## 1. What is Bash?

**Bash** is a narrative-driven terminal simulation game, where the player steps into the role of a graduate researcher investigating a mysterious disappearance. Their goal is to master a fully functional virtual Linux shell, using real-world commands to traverse directories, write automation scripts, decrypt logs, and piece together a conspiracy hidden within the system's code. The game blends the authentic technical depth of programming puzzlers—like *Hacknet*, *TIS-100*, and *SeekL*—with the immersive, environmental storytelling and puzzle progression of *Portal*.

![HackNet](https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/365450/1e29fd71c7868652cee45ba70c1575087c5dbe55/header.jpg?t=1758156718)
![Portal 2](https://upload.wikimedia.org/wikipedia/en/f/f9/Portal2cover.jpg)

---

## 2. Design Pillars

We use design pillars to focus our design choices as we move through the project. For the purpose of this project, we want our design pillars to identify the types of fun or enjoyment which are key to the user experience.

1.  **Intellectual Problem Solving** - The user must solve puzzles using a set of tools, the Bash scripting language and Linux terminal, to progress through the narrative. Apart from the tutorial stages, the player is not coddled through a "tutorial hell"; instead, the game is open-ended and exploratory, encouraging the user to find the correct command or program required to produce an output.
2.  **Creation** - The player must create their own Bash scripts in order to solve problems. The player can take pride in the fact that they wrote the solutions to missions themselves, and take ownership of those solutions, sharing them on forums as game guides, or bragging to their friends about code golf.
3.  **Immersion** - The terminal is a daunting beast for many initially, and while the cyberpunk chat window offers familiarity to messaging applications like Discord or WhatsApp, the familiarity stops there. The user is thrown into the deep end of a Linux terminal with Bash scripting capabilities.
4.  **Advancement and Completion** - Not only is it a game, but it is a game that teaches you the fundamentals of the Linux terminal, Bash, SSH, and SQL. The player learns to code while progressing through an engaging narrative, where the skills of Bash scripting and terminal manipulation are practiced until they become muscle memory.
5.  **Discovery** - The narrative of the game has a theme of discovery. In particular, a scientific discovery of a silicon-based biological neural network in Wellington, New Zealand's very own Cook Strait. Not only is there a scientific discovery, but also a suspicious disappearance of one of our main protagonists. The user must unravel the mystery of both, finding that their paths are intertwined.

[14 Pillars of Fun Reference](https://www.gamedeveloper.com/design/fourteen-forms-of-fun)

---

## 3. Audience and Market

The game is designed to be played single-player on Steam. A demo will be released on Itch.io of the early game for playtesting of an early build.

The game will contain a mystery-based narrative about a scientific discovery and a murder mystery, with some adult themes of violence. The game will be aimed at teen to mature audiences, Linux enthusiasts, and anyone interested in learning to code.

---

## 4. Setting and World

**Location:** The Deep Sea Institute (DSI), Wellington, New Zealand.

The game takes place entirely within the **"Gatekeeper"** workstation, a high-security terminal connected to a subterranean research facility on the rugged coast of the Cook Strait. While the player never physically leaves the desk, the world is built through environmental storytelling: atmospheric sound design of the facility's hum, email timestamps, and weather reports from the stormy harbor outside.



**The Entity:**
Lurking in the sediment of the harbor is a **silicon-based biological neural network**. Unlike carbon life, this entity interacts with digital systems, blurring the line between biological infection and computer virus.

**Time Period:** Near-future (2026). The technology is grounded and realistic, but the biological discovery hints at sci-fi horror.

---

## 5. Narrative

The story unfolds over a series of "Days," each representing a distinct narrative act.

**Act 1: The Clean Up (Day 1)**
Jesse Wood (the player) starts their first day as a Research Assistant. Their supervisor, **Dr. Aris**, instructs them to "clean up" the workstation of the previous researcher, **Dr. Vance**, who was abruptly "dismissed."
* **The Conflict:** While deleting files, Jesse finds encrypted breadcrumbs left by Vance. A `.journal` file reveals that Vance didn't leave voluntarily—she was silenced for discovering that the sensor data wasn't just noise; it was a language.

**Act 2: The Logic Bomb (Day 2)**
Dr. Aris attempts to remotely wipe the drive to bury the evidence.
* **The Twist:** A fragment of Dr. Vance’s work—a rudimentary AI—survives in the volatile memory (`/tmp`).
* **The Action:** The player must work with the **Vance AI** to restore the scrubbed partitions using a recovered shell script (`vance_recovery.sh`), bypassing logic traps left by Aris.

**Act 3: The Uplink (Day 3)**
With the drive restored, the player and Freya (an external contact) trace the "sensor drift" Aris is hiding.
* **The Climax:** Using loops and `grep` to parse massive log files, the player triangulates a signal coming from a boat in the harbor. The signal isn't telemetry; it's a biological uplink. The entity is growing, and the Institute isn't studying it—they are feeding it.



---

## 6. Character Designs

* **Jesse Wood (Protagonist):** A graduate engineering student. Competent but low-level. The player's avatar. They are initially just doing a job but are pulled into the conspiracy by their curiosity.
* **Dr. Aris (Antagonist):** The Lead Administrator. Bureaucratic, cold, and controlling. He speaks in corporate euphemisms ("Hardware fatigue," "HR matter") to mask the horror of what the Institute is doing. He represents the "System" the player must hack against.
* **Dr. Vance (The Mystery):** The former Senior Researcher. Brilliant and paranoid. Though she is physically absent, her personality shines through her code comments, hidden logs, and the chaotic state of her directory.
* **Vance AI (The Ally):** A digital echo of Dr. Vance. Whether it is a true AI or just a sophisticated script she left behind is ambiguous. It serves as the player's guide for advanced hacking concepts.
* **Freya (The Grounding):** Jesse's friend outside the institute. She provides the emotional stakes and reminds the player of the human world outside the cold command line.

---

## 7. Core Gameplay

The player starts off at a boot screen and is promptly shown a command-line terminal interface alongside a chat window. The user can enter commands to manipulate the terminal and follow instructions in the form of objectives given through the chat window. A group of objectives forms a chapter, and each chapter is a day in game time.

**Gameplay Loop:**
1.  **The Assignment:** The player receives a task via the Chat Window (e.g., "Find the coordinates in the logs").
2.  **The Investigation:** The player uses exploration commands (`ls`, `cd`, `tree`) to navigate the directory structure.
    
3.  **The Tool Selection:** The player identifies the right binary for the job (e.g., `grep` for search, `chmod` for permissions).
4.  **The Synthesis:** For complex problems, the player uses the **Nano Editor** to write Bash scripts, combining variables, loops, and logic (`if/else`) to automate the solution.
5.  **The Execution:** The player runs their script in the terminal. If it fails, they receive authentic error messages to help them debug.

---

## 8. Controls

* **Typing in the terminal**
    * Linux commands
    * Bash scripting
* **Terminal keyboard shortcuts**
    * `Ctrl + A` - Start of the line
    * `Ctrl + E` - End of line
    * `Ctrl + U` - Clear line
    * `Ctrl + L` - Clear screen
    * `Ctrl + O` - Save (Nano)
    * `Ctrl + X` - Exit (Nano)

---

## 9. Gameplay Balance & Pacing

The player starts off in a tutorial-like environment, where commands are explicitly given to them, and they repeat them verbatim into the terminal. As the chapters progress, the training wheels come off, and the user is left to their own devices on how to reach the objective.

**Progression:**
* **Day 1 (Tutorial):** Explicit instructions. "Run `ls`."
* **Day 2 (Puzzle):** Goal-oriented. "The script won't run. Fix the permissions." (Player must recall `chmod`).
* **Day 3 (Exam):** Open-ended. "Find the needle in the haystack." (Player must write a loop).

They are given a `help` command which lists all available commands, a `man` command which lists the documentation available for each command, and a test suite (`test_bash.sh`) which shows the features of the Bash scripting language in action.

---

## 10. Tone and Aesthetics

The visual style and iconography of the game will be developed as the project progresses. Initial inspirations include the Dracula color palette and TV shows like *Mr. Robot*.

**Key Visuals:**
* High-contrast, syntax-highlighted text.
* Retro-futuristic CRT effects (scanlines, chromatic aberration).
* A claustrophobic, dark interface reflecting the underground setting.

![Dracula](https://draculatheme.com/images/pro/vscode/1.png)
![Mr Robot Hack](https://www.slate.com/content/dam/slate/articles/technology/future_tense/2016/08/160901_FT_mr-robot-hack.jpg.CROP.promo-xlarge2.jpg)
![Mr Robot Terminal](https://hackers-arise.com/wp-content/uploads/2023/12/6a4a49_e3b82b0cb12646749ae58ec8c1c970bamv2-3.jpg)

---

## 11. Business Model

This is a premium game which users will purchase once and then own for good. The game will release as follows:

1.  An initial limited-features free demo release to gain initial interest and traction (Itch.io).
2.  A Kickstarter campaign to raise funds to develop all features and content which are beyond the scope of this initial design document.
3.  A full premium release in the under-$10 category, with Kickstarter backers receiving Steam keys plus whatever in-game rewards have been arranged.
