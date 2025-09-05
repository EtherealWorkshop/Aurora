# Aurora
A tool similar to Ventoy for ChromeOS RMA shims and recovery images based on Alpine Linux<br><br>
![i spend too much time working](https://hackatime-badge.hackclub.com/U085HGVQE9F/Aurora)
# What works? What doesn't?
Recovery :white_check_mark:<br>
Payloads menu :white_check_mark:<br>
Booting other shims :white_check_mark:<br>
Wifi :white_check_mark:<br>
Synaptic :x:<br>

# Priorities
1. Wifi on all possible ARM boards
2. general improvement
3. aurora 2.0
4. docs

# Building

## Dependencies
### Arch Linux:
```bash
sudo pacman -Sy wget curl gptfdisk rsync binwalk e2fsprogs && yay -S vboot-utils
```
### Debian:
```bash
sudo apt install wget curl bash e2fsprogs gdisk cgpt rsync
```
### Alpine:
```bash
apk add curl wget bash e2fsprogs gptfdisk sgdisk cgpt rsync
```

## Building
```bash
git clone --recursive https://github.com/EtherealWorkshop/Aurora.git
cd Aurora
```
Run the next command with a **raw** shim and the architecture of the chromebook you have.
```bash
sudo bash Aurora /path/to/shim.bin
```
Alternatively, you can automatically download a nanoshim and build with it with the following command:
```bash
sudo bash Aurora <board> --auto
```
If you don't want to build a shim yourself (or aren't able to), prebuilts are available on the [latest release](https://github.com/EtherealWorkshop/Aurora/releases/latest).
## Flashing
### Linux:
Assuming you're still cd'd into `Aurora/` and have just built it.
First run `lsblk` and look for the usb's identifier (the letter after sd), replace "X" with it.
```bash
sudo dd if=<board>-aurora.bin of=/dev/sdX bs=1M status=progress
```
Otherwise, do `if=/path/to/<board>-aurora.bin` if you aren't working in the same directory as the prebuilt.
### Windows:
Download Rufus, select your usb, select board-aurora.bin (download from prebuilts, or try to build with WSL). 

### MacOS:
Download Balena Etcher, select your usb, select board-aurora.bin. 

### ChromeOS (sh1tty00be'd or otherwise unenrolled)
Download a prebuilt, get the [chromebook recovery utility](https://chromewebstore.google.com/detail/chromebook-recovery-utili/pocpnlppkickgojjlmhdmidojbmbodfm). Start CRU and click the gear icon in the top right, press "use local image" and navigate to the prebuilt. Select your usb, and let it do its thing. 
Fun fact, you can also do this for stuff like badbr0ker, meaning you don't need a pc to unenroll now if you're willing to use prebuilts, just a chromebook!<br>
# Booting
After flashing, do the normal steps to boot sh1mmer, then plug it into your chromebook. It will automatically extend the rootfs to fill the rest of the drive. On future boots if you're connected to the internet it will automatically update itself. 
You can then either download recovery images or shims in Aurora itself, or put them on Aurora via mounting the 4th partition of the device on another linux/chromeos machine and copying them into the relevant directory inside `/usr/share/aurora/images` on the mounted drive (there's images/recovery, images/shims, and images/gurt [yo]).
# Booting Other Shims
- Here's a list of shims that are built in to not boot:
  1. Raw shims  -  You don't need to boot a raw shim. The raw shim option in SH1MMER has also been removed when booted in Aurora.
  2. Priism and IRS - Aurora is quite literally a merger of these two.
- Here's a list of shims that we've tested and they work:
  1. SH1MMER (contains cryptosmite, icarus, and br0ker)
  2. Shimboot (:3)
  3. KVS
  4. Aurora (great scott!)
- Here's a list of shims we're gonna make work and test:
  1. Any future shims that are made

# Uploading Files via another computer
1. Use AFT on page 2 (reccomended)
2. Use a linux computer with **ROOT ACCESS** ChromeOS Files will NOT WORK! Use VT2 if you only have a chromebook.

# Credits
- [Sophia](https://github.com/soap-phia) - Lead developer of Aurora, Got Wifi
- [Mariah Carey](https://github.com/xXMariahScaryXx) - Bugfixing and bugtesting, mostly the latter
- [xmb9](https://github.com/xmb9) - [PRIISM] Made Priism, Giving Aurora the ability to Boot Shims & Use Reco Images
- [EpicDevices](https://github.com/epic-devices) - Inspired the `wifidevice` variable and also is very epic
- [Synaptic](https://github.com/Synaptic-1234) - Emotional Support
- [Simon](https://github.com/simpansoftware) - [IRS] Brainstormed how to do wifi, helped with determining wireless interface
- [kraeb](https://github.com/DyingHynixMLC) - [IRS] QoL improvements and initial idea
- [Evie](https://github.com/AC3GT) - Literally nothing
