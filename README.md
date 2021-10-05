## USB (including a 3.5mm jack and an internal speaker) sample rate changer for Android devices on the fly

Under Magisk environment (<strong>"root name space mount mode" must be changed to "global"</strong> in the settings of Magisk Manager), this script changes the sample rate of the USB (including haedware offloading) audio class driver on Android devices on the fly like Bluetooth LDAC or Windows mixer for <q><em>avoiding annoying SRC (Sample Rate Conversion) distorsions</em></q>. This script signals the audioserver on the "global" mount name space to try to reaload an audio policy configuration file generated by this script with a specified sample rate and bit depth, so the "root name space mount mode" change is needed.

* Usage: `sh /sdcard/USB_SampleRate_Changer/USB_SampleRate_Changer.sh [--reset][--auto][--usb-only][--legacy][--offload][--bypass-offload][--safe][-safest] [--drc] [[44k|48k|88k|96k|176k|192k|353k|384k|706k|768k] [[16|24|32]]]`,

  if you unpack the archive under "/sdcard" (Internal Storage). The arguments are a sample rate and a bit depth to which you want to change, respectively.

  - Options
    - `--reset`(without arguments): resets its previous execution results.
    - `--auto`: investigates device's environment and changes an audio policy configuration file appropriately in most situations. (default behavior)
    - `--usb-only`: changes a USB audio policy configuration file only.
    - `--legacy`: changes an audio policy configuration file for a Bluetooth audio legacy HAL (<em>/system/{lib,lib64}/hw/audio.a2dp.default.so</em>).
    - `--offload`: changes an audio policy configuration file for (USB & Bluetooth) hardware offloading. 
    - `--bypass-offload`: changes an audio policy configuration file for bypassing (USB & Bluetooth) hardware offloading and using a non- hardware offload USB & Bluetooth audio drivers while a 3.5mm jack and an internal speaker use a hardware offloading driver.
    - `--safe`: changes an audio policy configuration file for a Bluetooth audio legacy HAL, but keeps considerably traditional settings for an internal speaker and others.
    - `--safest`: changes an audio policy configuration file for a Bluetooth audio legacy HAL, but keeps most traditional settings for an internal speaker and others.
    - `--drc`: enables DRC (Dynamic Range Control or simply compression) for the purpose of comparison to usual DRC-less audio quality (not effective for --usb-only mode).

* Note: "USB_SampleRate_Changer.sh" requires to unlock the USB audio class driver's limitation (upto 96kHz lock or 384kHz offload lock) if you want to specify greater than 96kHz or 384kHz (in case of USB hardware offloading, i.e. maybe hardware offload tunneling). See my companion magisk module ["usb-samplerate-unlocker"](https://github.com/yzyhk904/usb-samplerate-unlocker) for non- hardware offload drivers. Although you specify a high sample rate for this script execution, you cannot connect your device to a USB DAC with the sample rate unless the USB DAC supports the sample rate (the USB driver will limit the connecting sample rate downto its maximum sample rate).
* Tips 1: You can see the sample rate connecting to a USB DAC during music replaying by a command `cat /proc/asound/card1/pcm0p/sub0/hw_params` (for non- USB hardware offload drivers). You can also see mixer ("AudioFlinger") info by a command `dumpsys media.audio_flinger`. There are corresponding convenient scripts in "extras" folder.
* Tips 2: "jitter-reducer.sh" in "extras" folder is a simplified tool of ["Hifi Maximizer"](https://github.com/yzyhk904/hifi-maximizer-mod) which could reduce jitters relating to SELinux mode, thermal control, CPU&GPU governors, camera server, I/O scheduling, virtual memory and audio effectors framework.
* Tips 3: Please disable battery optimizations for following app's manually through the settings UI of Android OS (to lower less than 10Hz jitter making reverb like distortions). music players, their licensing apps, "bluetooth" (system app), "Android Services Library", "Android Shared Library", "Android System", launcher app, "Google Play Services", "Magisk", "PhhTrebleApp", keyboard app, kernel adiutor, etc.

I recommend to use Script Manager or like for easiness.

## DISCLAIMER

* I am not responsible for any damage that may occur to your device, 
   so it is your own choice to attempt this script.

## Change logs

# v1.0
* Initial Release

# v1.1
* Recent higher sample rates added

# V1.2
* (USB) hardware offload support added (currently experimental)
* Bypass (USB) offload (using a non- USB hardware offload driver while the 3.5mm jack and internal speaker use a hardware offload driver) support added (currently experimental)

# V1.3
* Selinux enforcing mode bug fixed. Now this script can be used under both selinux enforcing and permissive modes

# V2.0
* Support "disable a2dp hardware-offload" in dev. settings and PHH treble GSI's "force disable a2dp hardware-offload"
* Setting an r_submix HAL to be 44.1kHz 16bit mode
* Add "auto" mode for investigating device's environment and guessing best settings

# V2.1
* ``--drc`` option added for the porpus of comparison to usual DRC-less audio quality

# V2.2
* extras/jitter-reducer.sh (a simplified version of my ["Hifi Maximizer"](https://github.com/yzyhk904/hifi-maximizer-mod)) added
