#!/bin/bash

# Copyright 2025 Aerialite Labs. All rights reserved.
# Use of this source code is governed by the GNU AGPLv3 license
# that can be found in the LICENSE.md file.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# THE COPYRIGHT HOLDERS, SPECIFICALLY SOPHIA, ARE NOT LIABLE FOR BAD CODE
# BY USING THIS SOFTWARE, YOU ALSO AGREE THAT AERIALITE LABS HAS
# THE LEGAL RIGHTS TO YOUR FIRSTBORN CHILD, AND MAY STEAL ANY OF
# YOUR CHILDREN AND THROW THEM ON A ROAD DURING ONCOMING TRAFFIC.
# DAMAGES INCLUDE, BUT ARE NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

cd /
source /usr/share/aurora/functions
stty sane
stty erase '^H'
stty intr ''
stty -echo
export stty=$(stty -g)
stty echo

export TTY1="/run/frecon/vt0" TTY2="/run/frecon/vt1" TTY3="/run/frecon/vt2" TTY4="/run/frecon/vt3"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export_args $(cat /proc/cmdline | sed -e 's/"[^"]*"/DROPPED/g') 1> /dev/null

#################
## DEFINITIONS ##
#################

export aroot="/usr/share/aurora"
export releaseBuild=1
export shimroot="/shimroot"
export recoroot="/recoroot"
export rogged=$((RANDOM % 100))
export debug=false
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias grep='grep --color=auto'
mkdir -p $aroot/images/shims
mkdir -p $aroot/build
mkdir -p $aroot/images/recovery
rm -f /etc/aftggp /etc/kernverpending

############
## IMAGES ##
############

installcros() {
    chmod +x /usr/bin/bigtext
    bigtext installcros
	if [[ -z "$(ls -A $aroot/images/recovery 2>$TTY4)" ]]; then
        echo -ne "${YELLOW_B}"
		echo "You have no recovery images downloaded! Please download a few images" | center
		echo "Alternatively, these are available on websites such as chrome100.dev or cros.tech. Put them into /usr/share/aurora/images/recovery" | center
        read_center "Press Enter to return to the main menu"
        echo -ne "${COLOR_RESET}"
		return
	else
        mapfile -t recochoose < <(find "$aroot/images/recovery" -type f)
        reco_options=("${recochoose[@]}" "Exit") # haha 69
        while true; do
            menu "Choose the recovery image you want to boot" "${reco_options[@]}"
            choice=$?
            reco="${reco_options[$choice]}"
            if [[ "$reco" == "Exit" ]]; then
                read_center "Press Enter to continue..."
                return
            fi
            break
        done
	fi
    stty echo
    tput cnorm
    read_center -d "This will wipe your ChromeOS drive. Please type 'confirm' to continue: " confirmation
    tput civis
    if [ ! "$confirmation" = "confirm" ]; then echo "Exiting..." | center; sleep 2; return; fi
    if (( $(cat /sys/class/power_supply/BAT0/capacity) <= 20 )) && [ "$(cat /sys/class/power_supply/BAT0/status)" != "Charging" ]; then
        fail "Battery Power below 20%. Please plug in your device."
    fi
    mkdir -p $recoroot
    echo -e "Searching for ROOT-A on reco image" | center
    loop=$(losetup -fP --show $reco)
    loop_root="$(cgpt find -l ROOT-A $loop | head -n 1)"
    [ -n "$loop_root" ] || fail "Invalid recovery image"
    if mount -r "${loop_root}" $recoroot ; then
        echo -e "ROOT-A found successfully and mounted." | center
    else
        fail "Failed to mount ROOT-A"
    fi
    local cros_dev="$(get_largest_cros_blockdev)"
    if [ -z "$cros_dev" ]; then
        echo -e "${YELLOW_B}No ChromeOS drive was found on the device! Please make sure ChromeOS is installed before using Aurora. Continuing anyway${COLOR_RESET}" | center
    fi
    stateful="$(cgpt find -l STATE ${loop} | head -n 1 | grep --color=never /dev/)" || fail "Failed to find stateful on ${loop}!"
    mkdir -p /mnt/stateful_partition
    mount $stateful /mnt/stateful_partition || fail "Failed to mount stateful!"
    cd $recoroot
    d=""
    for d in /proc /dev /sys /tmp /run /var /mnt/stateful_partition; do
        mount -n --bind "${d}" "./${d}"
        mount --make-slave "./${d}"
    done
    DEFAULT_ROOTDEV=$(jq -r '.load_base_vars.DEFAULT_ROOTDEV' usr/sbin/partition_vars.json)
    drive=$(get_fixed_dst_drive)
    read_center -d "Block ChromeOS and Kernel Updates? (Y/n): " block
    case $block in
        n|N) chroot ./ /usr/sbin/chromeos-install --payload_image="${loop}" --yes || fail "Failed during chroot!" --fatal ;;
        *) echo_c "Blocking Updates" GEEN_B | center
           mount -n --bind /usr/share/aurora/assets/chromeos-install.sh ./usr/sbin/chromeos-install.sh
           debug_run chroot ./ /usr/sbin/chromeos-install --payload_image="${loop}" --yes --minimal_copy || fail "Failed during chroot!" --fatal 
           umount ./usr/sbin/chromeos-install.sh
           ;;
    esac # see, "case" spelled backwards is "esac", which is funny because until i've had my "case", i don't give "esac" about anything.
    local cros_dev="$(get_largest_cros_blockdev)"
    cgpt add -i 2 $cros_dev -P 15 -T 15 -S 1 -R 1 || echo -e "${YELLOW_B}Failed to set kernel priority! Continuing anyway${COLOR_RESET}"
    clear
    source /usr/share/aurora/functions
    bigtext installcros
    echo "lsblk output" | center
    echo ""
    lsblk
    echo ""
    echo_c "Finished! Press any key to reboot." GEEN_B | center
    read -n1
    reboot -f
    sleep 3
    fail "Reboot failed." --fatal
}

shimboot() {
    chmod +x /usr/bin/bigtext
    bigtext shimboot
	if [[ -z "$(ls -A $aroot/images/shims)" ]]; then
        echo -e "${YELLOW_B}You have no shims downloaded!\nPlease download or build a few images." | center
		echo "Alternatively, shims are available in https://github.com/AerialiteLabs/[Sh1mmer, Aurora]/releases. Put them into /usr/share/aurora/images/shims" | center
        read_center "Press Enter to return to the main menu..."
        echo -e "${COLOR_RESET}"
		return
	else
        mapfile -t shimchoose < <(find "$aroot/images/shims" -type f)
        shim_options=("${shimchoose[@]}" "Exit")

        while true; do
            menu "Choose the shim you want to boot:" "${shim_options[@]}"
            choice=$?
            shim="${shim_options[$choice]}"
            if [[ "$shim" == "Exit" ]]; then
                read_center "Press Enter to continue..."
                return
            fi
            break
        done
	fi

    mkdir -p $shimroot
    echo -e "Searching for ROOT-A on shim" | center
    loop=$(losetup -Pf --show $shim)
    export loop
    if lsblk -o PARTLABEL $loop | grep "shimboot"; then
        sed -i 's/shimboot=0/shimboot=1/' /auroraroot/etc/aurora
        sync
        stty echo
        fail "Shimboot not currently available. Fixed shortly."
#        read_center -d "Reboot to boot into shimboot instead of Aurora from auroraboot? (Y/n): " bootshimboot
#        case $bootshimboot in
#            "n*"|"N*") return 0 ;;
#            *) losetup -D
#               
#               reboot -f ;;
#        esac
    fi

    loop_root="$(cgpt find -l ROOT-A "$loop" | head -n1)"
    if [ -z "$loop_root" ]; then
            loop_root="$(cgpt find -t rootfs "$loop" | head -n1)"
    fi
    if [ -z "$loop_root" ]; then
        loop_root="${loop}p3"
    fi
    echo $loop_root
    if mount "${loop_root}" $shimroot; then
        echo -e "ROOT-A found successfully and mounted." | center
    else
        fail "Failed to mount ROOT-A"
    fi
    export skipshimboot=0
    if ! stateful="$(cgpt find -l STATE ${loop} | head -n 1 | grep --color=never /dev/)"; then
        echo -e "${YELLOW_B}Finding stateful via partition label \"STATE\" failed (try 1...)${COLOR_RESET}" | center
        if ! stateful="$(cgpt find -l SH1MMER ${loop} | head -n 1 | grep --color=never /dev/)"; then
            echo -e "${YELLOW_B}Finding stateful via partition label \"SH1MMER\" failed (try 2...)${COLOR_RESET}" | center

            for dev in "$loop"*; do
                [[ -b "$dev" ]] || continue
                parttype=$(udevadm info --query=property --name="$dev" 2>$TTY4 | grep '^ID_PART_ENTRY_TYPE=' | cut -d= -f2)
                if [ "$parttype" = "0fc63daf-8483-4772-8e79-3d69d8477de4" ]; then
                    stateful="$dev"
                    break
                fi
            done
        fi
    fi
    if [[ -z "${stateful// }" ]]; then
        echo -e "${RED_B}Finding stateful via partition type \"Linux data\" failed (try 3...)${COLOR_RESET}" | center
        echo -e "Last resort (try 4...)" | center
        stateful="${loop}p1"
    fi
    echo "Found Stateful at $stateful" | center
    if (( $skipshimboot == 0 )); then
        mkdir -p /stateful
        mkdir -p /newroot
        mount -t tmpfs tmpfs /newroot -o "size=1024M" || fail "Failed to allocate 1GB to /newroot"
        mount $stateful /stateful || fail "Failed to mount stateful!"
        sh1mmerfile="/stateful/root/noarch/usr/sbin/sh1mmer_main.sh"
        version="legacy"
        if [ -f /stateful/root/noarch/usr/sbin/sh1mmer_gui.sh ]; then
            version="bw"
        fi
        if lsblk -o PARTLABEL $loop | grep "SH1MMER"; then
            if ! grep -q "rm -f /etc/resolv.conf" "$sh1mmerfile"; then
                sed -i '/^#!\/bin\/bash$/a export PATH="/bin:/sbin:/usr/bin:/usr/sbin"\nrm -f /etc/resolv.conf\necho "nameserver 1.1.1.1" > /etc/resolv.conf' "$sh1mmerfile"
            fi
            cp /usr/share/patches/sh1mmer/$version/bootstrap/noarch/init_sh1mmer.sh /stateful/bootstrap/noarch/init_sh1mmer.sh && echo "Successfully patched bootstrap"
            cp /usr/share/patches/sh1mmer/$version/root/noarch/* -r /stateful/root/noarch/ && echo "Successfully patched root"
            chmod +x /stateful/bootstrap/noarch/init_sh1mmer.sh
            canwifi rm /stateful/root/noarch/payloads/mrchromebox.sh
            canwifi curl -sLk https://mrchromebox.tech/firmware-util.sh -o /stateful/root/noarch/payloads/mrchromebox.sh
            sync
            chmod +x $sh1mmerfile
        fi

        copy_lsb
        
        echo "Copying rootfs to ram..." | center
        pv_dircopy "$shimroot" /newroot

        mkdir -p /newroot/dev/pts /newroot/proc /newroot/sys /newroot/tmp /newroot/run
        mount -t tmpfs -o mode=1777 none /newroot/tmp
        mount -t tmpfs -o mode=0555 run /newroot/run
        mkdir -p -m 0755 /newroot/run/lock

        for mnt in /dev /proc /sys; do
            mount --move "$mnt" "/newroot$mnt" || fail "Failed to mount $mnt"
        done

        if ! mountpoint -q /newroot/dev/pts; then
            mount -t devpts devpts /newroot/dev/pts
        fi

        echo "Done" | center
        echo "About to switch root. If your screen goes black and the device reboots, please make a GitHub issue if you're sure your shim isn't corrupted" | center
        echo "Switching root" | center
        clear

        mkdir -p /newroot/tmp/aurora
        if [ -n "$specialshim" ]; then
            rm -f /newroot/sbin/init
            cp /usr/share/patches/sh1mmer/bootstrap/noarch/sbin/init /newroot/sbin/init
            chmod +x /newroot/sbin/init
        fi
        if [ -f "/newroot/bin/kvs" ]; then  
            chmod +x /newroot/bin/kvs
            cat <<EOF > /newroot/sbin/init
#!/bin/bash
/bin/kvs
EOF
        fi
        chmod +x /newroot/sbin/init
        stty echo
        tput cnorm
        debug_run pivot_root /newroot /newroot/tmp/aurora
        echo "Successfully switched root. Starting init..."
        exec /sbin/init || {
            echo "Failed to start init"
            echo "Bailing out, you are on your own. Good luck."
            echo "This shell has PID 1. Exit = panic"
            echo $(/tmp/aurora/bin/uname -a)
            exec /tmp/aurora/bin/sh
        }
    fi
}

#chromium() {
#    apk add --no-progress pcre-tools
#    if [ ! -f /usr/sbin/setup-xorg-base ] && [ ! -f /usr/sbin/setup-devd ]; then
#        mkdir -p "/tmp/apk-tools-static"
#        wget -q --show-progress "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$(uname -m)/$(echo "$(wget -qO- --show-progress "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$(uname -m)/" | grep "apk-tools-static")" | pcregrep -o1 '"(.+?.apk)"')" -O "/tmp/apk-tools-static/pkg.apk"
#        tar --warning=no-unknown-keyword -xzf "/tmp/apk-tools-static/pkg.apk" -C "/tmp/apk-tools-static"
#        chmod +x /tmp/apk-tools-static/sbin/apk.static
#        /tmp/apk-tools-static/sbin/apk.static --arch $(uname -m) -X http://dl-cdn.alpinelinux.org/alpine/edge/main/ -U --allow-untrusted --root "/" --initdb add alpine-base
#        sync
#    fi
#    setup-xorg-base chromium gvfs font-dejavu openbox hsetroot
#    rc-update add dbus sysinit
#    openrc sysinit
#    rm ~/.xinitrc
#    cat <<EOF > ~/.xinitrc
#openbox &
#hsetroot -cover /usr/share/aurora/bg.png &
#while true; do
#    chromium --start-maximized --no-first-run --disable-infobars --disable-session-crashed-bubble --restore-last-session --no-sandbox
#done
#EOF
#    killall frecon-lite
#    startx
#}

##################
## OPTIONS MENU ##
##################

payloads() {
    mapfile -t payloadchoose < <(find "$aroot/payloads" -maxdepth 1 -type f 2>$TTY4)
    options_payload=()
    for f in "${payloadchoose[@]}"; do
        options_payload+=("$(basename "$f")")
    done
    options_payload+=("Exit")

    menu "Choose payload to run:" "${options_payload[@]}"
    choice=$?
    payload_name="${options_payload[$choice]}"
    if [[ $payload_name == "Exit" ]]; then
        return
    else
        for payload_path in "${payloadchoose[@]}"; do
            if [[ "$(basename "$payload_path")" == "$payload_name" ]]; then
                source "$payload_path"
                break
            fi
        done
        read_center "Press Enter to continue..."
        return
    fi
}

crosrun() {
    [ -f /usr/share/cros/usr/sbin/sh1mmer_main.sh ] || fail "Sh1mmer directory nonexistent."
    cat /usr/share/cros/usr/sbin/sh1mmer_main.sh | grep -q "patched by aurora" || fail "Sh1mmer Unpatched (How???)"
    stty echo
    tput cnorm
    mount --bind /usr/share/cros /usr/share/cros
    for mnt in /dev /proc /sys; do
        mkdir -p /usr/share/cros$mnt
        mount --bind "$mnt" "/usr/share/cros$mnt"
    done
    case $1 in
        shell) script="/bin/bash" ;;
        unenrollment) script="/usr/sbin/unenrollment.sh" ;;
        sh1mmer) script="/usr/sbin/sh1mmer.sh" ;;
        aub) script="/usr/sbin/updateblocker.sh" ;;
    esac
    chmod +x "/usr/share/cros${script}"
    TERM=linux
    chroot /usr/share/cros /bin/bash -c "${script}"
    for mnt in /dev /proc /sys; do
        umount "/usr/share/cros$mnt"
    done
    umount /usr/share/cros
}

##########
## WIFI ##
##########

download() {
    chmod +x /usr/bin/bigtext
    bigtext download
    	options_download=(
	    "ChromeOS recovery image"
	    "ChromeOS Shim"
        "Exit"
	)

	menu "Select an option (use ↑ ↓ arrows, Enter to select)" "${options_download[@]}"
	download_choice=$?
    clear
	case "$download_choice" in
	    0) downloadreco ;;
	    1) downloadshim ;;
        2) return 0 ;;
        *) fail "Invalid choice (somehow?????)" ;; 
	esac
}

downloadreco() {
    chmod +x /usr/bin/bigtext
    bigtext download
	versions || fail "Failed to get version"
    wget -q --show-progress "$FINAL_URL" -O "$aroot/images/recovery/$chromeVersion.zip" || {
        fail "Failed to download ChromeOS recovery image."
    }
    FINAL_FILENAME=$(unzip -Z1 "$aroot/images/recovery/$chromeVersion.zip")
    file "$aroot/images/recovery/$chromeVersion.zip" | grep -iq "zip" || {
        fail "ChromeOS recovery archive corrupted."
    }
    unzip "$aroot/images/recovery/$chromeVersion.zip" -d "$aroot/images/recovery/" || {
        fail "Failed to unzip ChromeOS recovery archive."
    }
	rm $aroot/images/recovery/$chromeVersion.zip
    mv $aroot/images/recovery/$FINAL_FILENAME $aroot/images/recovery/$chromeVersion.bin
    echo_c "Syncing filesystem" GEEN_B | center
    sync
}

downloadshim() {
    chmod +x /usr/bin/bigtext
    bigtext download
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD 2>$TTY4)
    export board_name=${release_board%%-*}
    	options_download=(
	    "Sh1mmer Legacy - AerialiteLabs/Sh1mmer/releases"
	    "Shimboot - ading2210/shimboot/releases"
        "Custom Shim from URL"
	)

	menu "Select an option (use ↑ ↓ arrows, Enter to select)" "${options_download[@]}"
	download_choice=$?

	case "$download_choice" in
	    0) export FINALSHIM_URL="https://github.com/AerialiteLabs/sh1mmer/releases/download/v2.0.0/${board_name}.bin" ;;
	    1) export FINALSHIM_URL="https://github.com/ading2210/shimboot/releases/download/v1.3.0/shimboot_${board_name}.zip" ;;
	    2) tput cnorm
           stty echo
           read_center -d "Enter Shim URL: " FINALSHIM_URL ;;
        *) fail "Invalid choice (somehow?????)" ;;
	esac
    shimtype=$(echo $FINALSHIM_URL | awk -F. '{print $NF}')
    if [ -z "$shimtype" ]; then
        fail "Invalid Shim URL"
    fi
    shimfile=$(echo $FINALSHIM_URL | awk -F/ '{print $NF}')
    shimname=$(echo $shimfile | sed "s/.${shimtype}//")
    if curl --head --silent --fail "$FINALSHIM_URL" >$TTY4; then
        wget -q --show-progress "$FINALSHIM_URL" -O "$aroot/images/shims/$shimfile" || {
            fail "Failed to download shim."
        }
    else
        fail "File does not exist."
    fi
    if [ "$shimtype" = "zip" ]; then
        FINALSHIM_FILENAME=$(unzip -Z1 "$aroot/images/shims/$shimfile")
        file "$aroot/images/shims/$shimfile" | grep -iq "zip" || {
            fail "Shim archive corrupted."
        }
        unzip "$aroot/images/shims/$shimfile" -d "$aroot/images/shims/" || {
            fail "Failed to unzip shim archive."
        }
    	rm $aroot/images/shims/$shimfile
    fi
    echo_c "Syncing filesystem" GEEN_B | center
    sync
}

updateshim() {
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    update-ca-certificates
    ntpd -q -p pool.ntp.org || true
    apk add --no-progress git >$TTY4 2>&1
    upd_dir=$(mktemp -d)
    cleanup() { 
        rm -rf "$upd_dir"
    }
    trap cleanup EXIT
    branch=$(auroraval origin)
    echo "Branch: $branch" | center
    if [ -d "/root/Aurora/.git" ]; then
        if ! git -C "/root/Aurora" pull origin "$branch" 2>&1 | center; then
            echo "git pull failed, recloning" | center
            rm -rf /root/Aurora
            git clone --branch="$branch" https://github.com/AerialiteLabs/Aurora /root/Aurora 2>&1 | center || return
        fi
    else
        rm -rf /root/Aurora
        git clone --branch="$branch" https://github.com/AerialiteLabs/Aurora /root/Aurora 2>&1 | center || return
    fi

    updated=0
    if ! cmp -s /usr/share/aurora/aurora.sh /root/Aurora/rootfs/usr/share/aurora/aurora.sh 2>"$TTY4"; then
        updated=1
    fi

    rsync -a --delete /root/Aurora/rootfs/ "$upd_dir/rootfs/"
    cp -a /etc/aurora "$upd_dir/etc.aurora.bak"

    cp -f "$upd_dir/rootfs/sbin/init" /sbin/init
    chmod +x /sbin/init
    cp -f "$upd_dir/rootfs/usr/share/aurora/aurora.sh" /usr/share/aurora/aurora.sh
    chmod +x /usr/share/aurora/aurora.sh
    cp -f "$upd_dir/rootfs/usr/share/aurora/functions" /usr/share/aurora/functions
    chmod +x /usr/share/aurora/functions
    sync # it shocks me people genuinely haven't learned you shouldn't reboot during updates. the fact i have to skidproof an update system is wild

    rsync -a --inplace --exclude="sbin/init" --exclude="usr/share/aurora/aurora.sh" --exclude="usr/share/aurora/functions" "$upd_dir/rootfs/" /
    mv -f "$upd_dir/etc.aurora.bak" /etc/aurora
    rsync -a --delete /root/Aurora/patches/sh1mmer/ /usr/share/patches/sh1mmer/
    chmod +x /usr/share/aurora/* /usr/bin/* /sbin/init
    sync
    aurorabootmnt=$(mktemp -d)
    aurorabootdev=$(lsblk -pro NAME,PARTLABEL,MOUNTPOINT | awk '/AuroraBoot/ {print $1; exit}')
    mount "$aurorabootdev" "$aurorabootmnt"
    rsync -a --inplace /root/Aurora/auroraboot/ "$aurorabootmnt/"
    rsync -a --inplace /root/Aurora/patches/shimboot/ "$aurorabootmnt/"
    chmod +x "$aurorabootmnt/bootstrap.sh" "$aurorabootmnt/sbin/init"
    sync
    umount $aurorabootmnt
    if [ "$updated" = "1" ]; then
        echo "Restarting aurora.sh" | center
        sleep 5
        exec bash /usr/share/aurora/aurora.sh
    fi
}

aftggp() {
    tput cnorm
    apk add --no-progress python3 py3-flask py3-bcrypt >$TTY4
    kill $(ps aux | grep "python3 /usr/share/ggp/" | grep -v grep | awk '{print $1}') 2>$TTY4
    rm -f /etc/aftggp
    read_center -d "Enter Password for AFT: " readpassword
    export readpassword
    python3 /usr/share/ggp/GGP.py > $TTY4 2>&1 &
    touch /etc/aftggp
}

connect() {
    ifconfig "$wifidevice" down
    pkill -12 udhcpc
    pkill udhcpc 2>$TTY4
    killall wpa_supplicant 2>$TTY4
    rm -rf /etc/wpa_supplicant* /etc/*dhcpc*
    ifconfig "$wifidevice" up
    [ -n "$DIS" ] && return
    echo_c "Available Networks\n" GEEN_B | center

    declare -A best
    while read -r line; do
        if [[ $line =~ ^signal: ]]; then
            signal=$(echo "$line" | awk '{print $2}' | sed 's/.00//')
        elif [[ $line =~ ^SSID: ]]; then
            ssid=$(echo "$line" | sed 's/^SSID: //' | tr -d '\000' | tr -d '[:cntrl:]' | sed 's/[[:space:]]*$//')
            [ -z "$ssid" ] && continue
            if [[ -z ${best["$ssid"]} || $signal -gt ${best["$ssid"]} ]]; then
                best["$ssid"]=$signal
            fi
        fi
    done < <(iw dev "$wifidevice" scan | tr -d '\000' | grep -E 'SSID:|signal:')

    networks=()
    for ssid in "${!best[@]}"; do
        networks+=("${best[$ssid]}:$ssid")
    done

    IFS=$'\n' sorted=($(printf "%s\n" "${networks[@]}" | sort -t: -k1 -nr))
    unset networks

    wifi_options=()
    for entry in "${sorted[@]}"; do
        signal=${entry%%:*}
        ssid=${entry##*:}

        if (( signal >= -50 )); then color=$'\e[1;38;5;82m▃▅▇\e[0m'
        elif (( signal >= -60 )); then color=$'\e[1;38;5;226m▃▅\e[1;38;5;236m▇\e[0m'
        elif (( signal >= -70 )); then color=$'\e[1;38;5;208m▃\e[1;38;5;236m▅▇\e[0m'
        else color=$'\e[1;38;5;196m▃\e[1;38;5;236m▅▇\e[0m'; fi

        wifi_options+=("$color $ssid")
    done
    wifi_options+=("Enter Network manually")
    wifi_options+=("Exit")

    while true; do
        menu "Choose a network" "${wifi_options[@]}"
        choice=$?
        ssid_option="${wifi_options[$choice]}"

        if [[ "$ssid_option" == "Exit" ]]; then
            read_center "Press Enter to continue..."
            return
        elif [[ "$ssid_option" == "Enter Network manually" ]]; then
            read_center -d "Enter SSID: " ssid
        else
            ssid=$(echo "$ssid_option" | sed -r 's/\x1B\[[0-9;]*m//g' | awk '{$1=""; sub(/^ /,""); print}')
        fi
        break
    done

    stty echo
    read_center -d "Enter password for $ssid: " psk
    conf="/etc/wpa_supplicant.conf"

    if grep -q "ssid=\"$ssid\"" "$conf" 2>$TTY4; then
        echo "Network (${ssid}) already configured." | center
    else
        if [ -z "$psk" ]; then
            cat >> "$conf" <<EOF
network={
    ssid="$ssid"
    key_mgmt=NONE
}

EOF
        else
            wpa_passphrase "$ssid" "$psk" >> "$conf"
        fi
		sync
    fi
    ip link set "$wifidevice" down
    ip link set "$wifidevice" up

    wpa_supplicant -B -i "$wifidevice" -c "$conf" >$TTY4

    for i in {1..15}; do
        if iw dev "$wifidevice" link | grep -q 'Connected'; then
            echo "Connected!" | center
            break
        fi
        sleep 1
    done

    if ! iw dev "$wifidevice" link | grep -q 'Connected'; then
        killall wpa_supplicant 2>$TTY4
        rm /etc/wpa_supplicant.conf
        return 1
    fi

    udhcpc -i "$wifidevice" 2>$TTY4 || {
        return 1
    }
}

wifi() {
    chmod +x /usr/bin/bigtext
    bigtext wifi
    stty echo
    export wifidevice=$(ip link | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
    if cat /sys/devices/virtual/dmi/id/product_name 2>$TTY4 | grep -Eqi 'treeya|barla' 2>$TTY4; then
        fail "Barla/Treeya wifi unsupported. Please contact @kxtzownsu on discord"
    fi
    if iw dev "$wifidevice" link 2>$TTY4 | grep -q 'Connected'; then
        echo "Currently connected to a network." | center
        read_center -d "Disconnect from this network? (y/N): " connectornah
        case $connectornah in
            y|Y|yes|Yes) DIS=1 connect || fail "Failed to connect." ;;
            *) ;;
        esac
    else
        connect || fail "Failed to connect."
    fi
    sync
}

pid1=false
if [ "$$" -eq 1 ]; then
    pid1=true
fi

menu1_options=(
    "1. Open Terminal"
    "2. Install a ChromeOS recovery image"
)

menu1_actions=(
    "clear && script -qfc 'stty sane && stty erase '^H' && exec bash -l || exec busybox sh -l' /dev/null"
    "clear && installcros"
)

if $pid1; then
    menu1_options+=("3. Boot a Shim")
    menu1_actions+=("clear && shimboot")
fi

menu1_options+=(
    "$( [ $pid1 = false ] && echo "3" || echo "4" ). Connect to WiFi"
    "$( [ $pid1 = false ] && echo "4" || echo "5" ). Download a ChromeOS recovery image/shim"
    "$( [ $pid1 = false ] && echo "5" || echo "6" ). Update shim"
    "$( [ $pid1 = false ] && echo "6" || echo "7" ). Payloads"
    "$( [ $pid1 = false ] && echo "7" || echo "8" ). Exit and Reboot"
)

menu1_actions+=(
    "clear && wifi"
    "canwifi clear && download"
    "canwifi updateshim && sync"
    "clear && payloads"
    "reboot -f"
)

menu2_options=(
    "1. Open Terminal"
    "2. AFTGGP [Aurora File Transfer]"
    "3. Build Environment"
    "4. Set Kernver"
)
menu2_actions=(
    "clear && script -qfc 'stty sane && stty erase '^H' && exec bash -l || exec busybox sh -l' /dev/null"
    "canwifi aftggp"
    "clear && canwifi aurorabuildenv"
    "clear && set-kernver"
)

menu3_options=(
    "1. Open a Cros Terminal"
    "2. Unenroll [Sh1mmer Deprovision, Cryptosmite, Br1ck, Icarus, Br0ker]"
    "3. Sh1mmer"
    "4. Block Updates"
)
menu3_actions=(
    "crosrun shell"
    "crosrun unenrollment"
    "crosrun sh1mmer"
    "crosrun aub"
)

#############
## STARTUP ##
#############

if $pid; then
    clear
    tput civis
    echo -e "$CYAN_B"
    cat <<'EOF' | center
╒════════════════════════════════════════╕
│ .    . .    '    +   *       o    .    │
│+  '.                    '   .-.     +  │
│          +      .    +   .   ) )     ''│
│                   '  .      '-´  *.    │
│     .    \      .     .  .  +          │
│         .-o-'       '    .o        o   │
│  *        \      *            +'       │
│                '       '               │
│        .*       .       o   o      .   │
│              o     . *.                │
│ 'o*           .        .'    .         │
│              ┏┓   '. O           *     │
│     .*       ┣┫┓┏┏┓┏┓┏┓┏┓  .    \      │
│     o        ┛┗┗┛┛ ┗┛┛ ┗┻     +        │
╘════════════════════════════════════════╛
EOF
    echo -e "${COLOR_RESET}"
fi
printf '\033c' > $TTY4
echo "Logging" >>$TTY4

for wifi in iwlwifi iwlmvm ccm 8021q rtw88 rtwpci ath10k_sdio mt7921e mt7921s mt76 rtw88_8822ce rtw8821ce rtw89pci; do
    modprobe -r "$wifi" 2>$TTY4 || true
    modprobe "$wifi" 2>$TTY4
done
modprobe -a iwlwifi iwlmvm ccm 8021q rtw88 rtwpci ath10k_sdio mt7921e mt7921s mt76 rtw88_8822ce rtw8821ce rtw89pci 2>$TTY4
sleep 2
if [ -e "/etc/wpa_supplicant.conf" ]; then
    ls /etc/wpa_supplicant.conf >$TTY4 2>&1
    for i in $(seq 1 60); do
        if compgen -G "/sys/class/net/wl*" >$TTY4; then
            break
        fi
        sleep 1
    done
    echo -e "[${GEEN_B}+${COLOR_RESET}] Connecting to wifi" | center
    export wifidevice=$(ip link | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
    ifconfig "$wifidevice" down
    pkill -12 udhcpc
    pkill udhcpc 2>$TTY4
    killall wpa_supplicant 2>$TTY4
    rm -rf /etc/*dhcpc*
    ifconfig "$wifidevice" up
    if [ -n "$wifidevice" ]; then
        wpa_supplicant -B -i "$wifidevice" -c /etc/wpa_supplicant.conf >"$TTY4" 2>&1
    else
        echo -e "[${RED_B}-${COLOR_RESET}] Failed to find wifi device. Please connect manually." | center
    fi
    connected=0
    for i in $(seq 1 30); do
        if iw dev "$wifidevice" link 2>>"$TTY4" | grep -q 'Connected'; then
            if udhcpc -i "$wifidevice" >>"$TTY4" 2>&1; then
                connected=1
                echo "success on attempt $i" >>"$TTY4"
            else
                echo "failure on attempt $i" >>"$TTY4"
            fi
            break
        fi
        sleep 1
    done

    if [ $connected -eq 0 ]; then
        echo -e "[${RED_B}-${COLOR_RESET}] No nearby saved networks found" | center
#    else
#        updateshim
#        sync
    fi
fi


release_board=$(lsbval CHROMEOS_RELEASE_BOARD 2>$TTY4)
export board_name=${release_board%%-*}

for chmod in /usr/bin/aurorabuildenv; do
    chmod +x $chmod
done
clear
export page=1 updatedpage=0
while true; do
	if ((page <= 0)); then
		export page=2
	elif ((page >= 3)); then
		export page=1
	fi
    export TERM=xterm-256color
    stty $stty
    eval "setup"
    clear
    hostname $(cat /etc/hostname)
    export wifidevice=$(ip link 2>$TTY4 | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
    splash
    errormessage
    export errormsg=""
    export login=""
    declare -n current_actions="menu${page}_actions"
    declare -n current_options="menu${page}_options"
    tput civis
    stty -echo
    menu "Select an option (use ← → ↑ ↓ arrows, Enter to select)" -p "${current_options[@]}"
    choice=$?
    if [[ -n "$updatedpage" && "$updatedpage" == "1" ]]; then
        updatedpage=0
        continue
    fi
    action="${current_actions[$choice]}"
    option="${current_options[$choice]}"
    echo ""

    if [[ "$action" == *"bash -l"* ]]; then
        cd /
        tput cnorm
        stty echo
        eval "$action"
    else
        stty $stty
        eval "$action"
    fi
    stty $stty
    sleep 1
done