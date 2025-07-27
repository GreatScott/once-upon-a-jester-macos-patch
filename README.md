# Once Upon a Jester MacOS Patch

The game, Once Upon a Jester, on MacOS (certain versions at least) have a game-crashing bug within a minute or two of starting the game that throws the following in an in-game pop-up:

```ERROR in
action number 1
of Step Event0
for object oControl:

audio_play_sound_on argument 2 invalid reference to (sound)##############
gml_Script_msg (line 41)
gml_Object_oControl_Step_0 (line 26641)
```

This is due to a sound file being improperly referenced or not-existing. The binary in this repo (built with ChatGPT's help) "tricks" the program into thinking valid audio always exists and simply won't play it instead of terminating the program due to uncaught exception.

This fix is originally built for Steam App ID: 1668190 / Build ID: 12603347 on MacOS 

(In Steam, right click on the game and navigate to Properties -> Updates to check your version).

## Important notes about this patch:
* This patch should be fairly universal for MacOS as long as the OS allows ad-hoc signing of binaries (Monterey->Sequoia) and symbols remain the same. Fix is for both Intel and Apple Silicon.
* If the devs update the game, this patch will need to be re-applied (assuming the bug is not fixed in the update)

## Installation

### Pre-requisites
(Installed in MacOS terminal)

1. Xcode command line tools `xcode-select --install`
2. LLVM `brew install llvm`
3. Python3 (if not already installed, though likely is)

### Usage
1. Download the bash (.sh file)
2. Open the bash file and verify that the paths to the installed game files are correct on your system or update if needed. Also update the path to where the backup should be stored if desired (default is Desktop)
3. Make the bash file executable `chmod +x patch_audio_exists_true.sh`
4. Run the script: `./patch_audio_exists_true.sh`
5. Launch game in steam. If it works, the game should continue and will just not play any missing audio.