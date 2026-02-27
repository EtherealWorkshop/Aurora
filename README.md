# Aurora
A tool similar to Ventoy for ChromeOS RMA shims and recovery images based on Alpine Linux<br><br>
![i spend too much time working](https://hackatime-badge.hackclub.com/U085HGVQE9F/Aurora)

> [!WARNING]
> Aurora is unstable and unmaintained. Please use [Priism](https://github.com/xmb9/Priism) instead.
> <br>If you really need Wi-Fi, Aurora is still the best option.
# What works? What doesn't?
Recovery :white_check_mark:<br>
Payloads menu :white_check_mark:<br>
Booting other shims :white_check_mark:<br>
Wi-Fi :white_check_mark:<br>
Synaptic :x:<br>

# Priorities
1. Wi-Fi on all possible ARM boards
2. General improvement
4. Aurora 2.0
5. Docs

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
git clone --recursive https://github.com/AerialiteLabs/Aurora.git
cd Aurora
```
Run the following command with a **raw** shim and the architecture of the Chromebook you have.
```bash
sudo bash Aurora /path/to/shim.bin
```
Alternatively, you can automatically download a nanoshim and build it with the following command:
```bash
sudo bash Aurora <board> --auto
```
If you don't want to build a shim yourself (or aren't able to), prebuilts are available on the [download server](https://dl.mrwork.shop).
## Flashing
### Linux/FreeBSD:
Assuming you're still in the `Aurora/` directory and have just built it:<br></br>
First, run `lsblk` and look for the USB's identifier (the letter after `sd`); replace "X" with it.
```bash
sudo dd if=<board>-aurora.bin of=/dev/sdX bs=1M status=progress
```
Otherwise, do `if=/path/to/<board>-aurora.bin` if you aren't working in the same directory as the prebuilt.<br></br>
Replace `sudo` with your privilege-escalation tool of choice.
### Windows:
Download Rufus, select your USB, select board-aurora.bin (download from prebuilts, or try to build with WSL). 

### macOS:
Download Balena Etcher, select your USB, select board-aurora.bin. 

### ChromeOS (personal/unenrolled device)
Download a prebuilt, get the [Chromebook Recovery Utility](https://chromewebstore.google.com/detail/chromebook-recovery-utili/pocpnlppkickgojjlmhdmidojbmbodfm). Start CRU and click the gear icon in the top right, press "use local image" and navigate to the prebuilt. Select your USB, and let it do its thing. 
# Booting
After flashing, do the normal steps to boot sh1mmer, then plug it into your Chromebook. It will automatically extend the rootfs to fill the rest of the drive. On future boots, if you're connected to the Internet, it will automatically update itself. 
You can then either download recovery images or shims in Aurora itself, or put them on Aurora by mounting the 4th partition of the device on another Linux/ChromeOS machine and copying them into the relevant directory inside `/usr/share/aurora/images` on the mounted drive (there's images/recovery, images/shims, and images/gurt [yo]).
# Booting Other Shims
- Here's a list of shims that we've tested and they work:
  1. SH1MMER (contains cryptosmite, icarus, and br0ker)
  2. KVS
  3. Aurora (great scott!)
- Here's a list of shims we're gonna make work and test:
  1. Shimboot (properly)
  2. Any future shims that are made

# Uploading Files via another computer
1. Use AFT on page 2 (recommended)
2. Use a Linux computer with **ROOT ACCESS**<br></br>
ChromeOS Files will NOT WORK! Use VT2 or Crostini USB passthrough if you only have a Chromebook.

# Credits
- [Sophia](https://github.com/soap-phia) - Lead developer of Aurora, Got Wifi
- [Mariah Carey](https://github.com/xXMariahScaryXx) - Bugfixing and bugtesting, mostly the latter
- [xmb9](https://github.com/xmb9) - [PRIISM] Made Priism, Giving Aurora the ability to Boot Shims & Use Reco Images
- [EpicDevices](https://github.com/epic-devices) - Inspired the `wifidevice` variable and also is very epic
- [Synaptic](https://github.com/Synaptic-1234) - Emotional Support
- [kraeb](https://github.com/DyingHynixMLC) - [IRS] QoL improvements and initial idea
- [Alva](https://github.com/4lvaret) - [IRS] Brainstormed how to do wifi, helped with determining wireless interface
- [kxtz](https://github.com/kxtzownsu) - Misc. README changes
- [Evie](https://github.com/AC3GT) - Literally nothing
