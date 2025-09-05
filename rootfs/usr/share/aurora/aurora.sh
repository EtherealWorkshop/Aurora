#!/bin/bash

# Copyright 2025 Ethereal Workshop. All rights reserved.
# Use of this source code is governed by the GNU AGPLv3 license
# that can be found in the LICENSE.md file.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# THE COPYRIGHT HOLDERS, SPECIFICALLY SOPHIA, ARE NOT LIABLE FOR BAD CODE
# BY USING THIS SOFTWARE, YOU ALSO AGREE THAT ETHEREAL WORKSHOP HAS
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
export TTY1="/dev/tty1" && export TTY2="/dev/tty2" && export LOGTTY="/dev/tty3" && export TTY3="/dev/tty4"
[ -e /dev/pts/0 ] && export TTY1="/dev/pts/0" && export TTY2="/dev/pts/1" && export TTY3="/dev/pts/3" && export LOGTTY="/dev/pts/2"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#################
## DEFINITIONS ##
#################

export aroot="/usr/share/aurora"
export releaseBuild=1
export shimroot="/shimroot"
export recoroot="/recoroot"
export rogged=$((RANDOM % 100))
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias grep='grep --color=auto'
mkdir -p $aroot/images/shims
mkdir -p $aroot/build
mkdir -p $aroot/images/recovery
declare -A VERSION
rm -f /etc/aftggp /etc/kernverpending

VERSION["BRANCH"]="alpine"
VERSION["NUMBER"]="1.0.0"
VERSION["BUILDDATE"]="[2025-08-14]"
VERSION["RELNAME"]="Rhymes with Grug"
VERSION["STRING"]="v${VERSION["NUMBER"]} ${VERSION["BRANCH"]} - \"${VERSION["RELNAME"]}\""

####################
## BASE FUNCTIONS ##
####################

# haha 69

funText() {
	splashText=(
        "${CYAN_B}The lower tape fade meme is still massive."
        "${LIGHT_BLUE_B}It most likely existed in the first place." 
        "${GEEN_B}HACKED BY GEEN" 
        "${LIGHT_BLUE_B}\"how do i type a backslash\" -simon" 
        "${PURPLE_B}MURDER DRONES SEASON 2 IS REAL I SWEAR"
        "${PURPLE_B}JCJENSON in SPAAAAAAC3"
        "${PURPLE_B}Well-made Quality Assured Durability" 
        "${YELLOW_B}\"purr :3 mrrow\" - Synaptic" 
        "${RED_B}who else but quagmire?\nhe's quagmire, quagmire,\nyou never really know what\nhe's gonna do next\nhe's quagmire, quagmire,\ngiggitygiggitygiggitygiggity\nlet's have [...]"
        "${GEEN_B}rhymes with grug"
        "${PINK_B}now with free thigh highs!"
        "${PINK_B}:3"
        "cr50 hammer? i think you meant \"no PoC\"."
        "public nuisance???\nis that a hannah reference"
        "${YELLOW_B}can you overdose on pepperjack cheese?"
        "${PURPLE_B}make me staff lil bro i'm overqualified..."
        "${YELLOW_B}:cheese;"
        "${YELLOW_B}toilet command best command!"
        "${CYAN_B}Sign in to Letterloop:\nHi friend,\nClick here to sign in with this magic link\n-Letterloop Team"
        "${GEEN_B}Also try Terraria!"
        "${GEEN_B}Terraria: Also try Minecraft"
        "${CYAN_B}HOW MANY HOLES IN A POLO??"
        "${CYAN_B}It's rewind time"
        "${CYAN_B}Ain't no party like a Putt Party"
        "${CYAN_B}Maxington hole 3"
        "${YELLOW_B}what's a nugget?"
        "${YELLOW_B}I'm gonna install a door on your face."
        "${RED_B}Anne Frank in a Furnace."
        "${CYAN_B}Use protection, Kids"
        "${PURPLE_B}Can Uzi use absolute solver on my dih?"
        "${GEEN}\"hi crazy ant\" - crazy ant"
        "${YELLOW_B}I'm gonna shove a cravat up your ass"
        "${CYAN_B}You barely sentient toaster."
        "${PINK_B}beautiful sophie art"
        "${YELLOW_B}Synaptic Network"
        "${BLUE_B}he could be in this very room!\nhe could be you!\nhe could be me!!"
        "${CYAN_B}Nothing built can last forever -ivor"
        "${CYAN_B}Your footjob is weak"
        "${CYAN_B}idk why age matters - shrey719"
        "${GEEN_B}gurt: yo"
        "${ORANGE_B}I am the Lorax and I speak for the trees"
        "${GEEN_B}CHICKEN JOCKEY"
        "${BLUE_B}stellaword12"
        "${YELLOW_B}the higher glue appear trend is now large."
        "${RED_B}one cannot simply walk into mordor\n- some dumbass who didn't walk into mordor"
        "${RED_B}i don't want a lot for christmas\n${GEEN_B}there is just one thing i need"
        "${GEEN_B}vermont isn't real"
        "${BLUE_B}\"Bite Me\" - Weird Al"
        "${PURPLE_B}Hi there. I'm SmallAnt1."
        "${CYAN_B}Man I sure do love InitramF5"
        "${LIGHT_BLUE_B}If a gay bomb was dropped - Zack D Films"
        "${YELLOW_B}swiss cheese yo ahhh"
        "${CYAN_B}you keep using that word\ni do not think it means what you think it means."
        "${CYAN_B}give me andrew"
        "${MAGENTA_B}it runs the demon - OlyB"
        "${YELLOW_B}GOOD MANNERS\n${RED_B}1 Wait your turn\n${BLUE_B}2 Use polite words\n${GEEN_B}3 Listen Carefully"
        "${YELLOW_B}mommy may I please have fakemod :3\n- synaptic"
        "${GREEN}crazy ant [...] :thumbsup:"
        "${CYAN_B}Nothing beats a Jet2 Holiday"
        "${PINK_B}\"soap\" manor"
        "${PURPLE_B}rogged"
        "${LIGHT_BLUE_B}Oh Reginald? I DISAGREE!"
        "${CYAN_B}Good News, Everyone!"
        "${RED_B}Error: Failed to find funText."
        "${PINK_B}Trans${LIGHT_BLUE_B} Rights${COLOR_RESET} Are${LIGHT_BLUE_B} Human${PINK_B} Rights"
        "${GEEN_B}Big news for the unemployed!"
        "${BLUE_B}blahaj"
        "${YELLOW_B}Shut Up, Synaptic!"
        "${YELLOW_B}We need to remove Antonios"
        "bash: line 182: tput: I/O error$(printf "%*s" "$(( $(tput cols) - 31 ))" "")bash: line 192: tput: I/O error$(printf "%*s" "$(( $(tput cols) - 31 ))" "")bash: line 194: tput: I/O error$(printf "%*s" "$(( $(tput cols) - 31 ))" "")"
        ) #              cen-><-ter" 

  	selectedSplashText=${splashText[$RANDOM % ${#splashText[@]}]}
	echo -e " "
   	echo -e "$selectedSplashText${COLOR_RESET}"
}


echo_c() {
    local text="$1"
    local color_variable="$2"
    local color="${!color_variable}"
    echo -e "${color}${text}${COLOR_RESET}"
}

echo_menu() {
    local text="$1"
    while IFS= read -r line; do
        local length=${#line}
        local spacing=$(( (42 - length) / 2 ))
        spacing=$((spacing < 0 ? 0 : spacing))
        printf "%*s%s\n" "$spacing" "" "$line"
    done <<< "$text"
}

menu() {
    local prompt="$1"
    shift
    local args=""
    if [[ "$1" == "-p" ]]; then
        args="$1"
        shift
    fi
    local options=("$@")
    local selected=0
    local count=${#options[@]}
    updatedpage=0
    tput civis
    echo "$prompt" | center
    for i in "${!options[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo "> ${options[i]} <" | center
        else
            echo "${options[i]}" | center
        fi
    done
    while true; do
        tput cuu $count
        for i in "${!options[@]}"; do
            tput el
            if [[ $i -eq $selected ]]; then
                echo "> ${options[i]} <" | center
            else
                echo "${options[i]}" | center
            fi
        done

        IFS= read -rsn1 key
        if [[ $key == $'\e' ]]; then
            read -rsn2 -t 0.01 key_rest
            key+="$key_rest"
        fi
        if [ "$args" = "-p" ]; then
            case $key in
                $'\e[A') ((selected--)) ;;
                $'\e[B') ((selected++)) ;;
				$'\e[D') export page=$((page - 1)) && export updatedpage=1 && return 255 ;;
				$'\e[C') export page=$((page + 1)) && export updatedpage=1 && return 255 ;;
                '') break ;;
            esac
        else
            case $key in
                $'\e[A') ((selected--)) ;;
                $'\e[B') ((selected++)) ;;
                '') break ;;
            esac
        fi
        ((selected < 0)) && selected=$((count - 1))
        ((selected >= count)) && selected=0
    done
    return $selected
}

get_largest_cros_blockdev() {
	local largest size dev_name tmp_size remo
	size=0
	for blockdev in /sys/block/*; do
		dev_name="${blockdev##*/}"
		echo -e "$dev_name" | grep -q '^\(loop\|ram\)' && continue
		tmp_size=$(cat "$blockdev"/size)
		remo=$(cat "$blockdev"/removable)
		if [ "$tmp_size" -gt "$size" ] && [ "${remo:-0}" -eq 0 ]; then
			case "$(sfdisk -d "/dev/$dev_name" 2>/dev/null)" in
				*'name="STATE"'*'name="KERN-A"'*'name="ROOT-A"'*)
					largest="/dev/$dev_name"
					size="$tmp_size"
					;;
			esac
		fi
	done
	echo -e "$largest"
}

splash() {
    if [ "$rogged" -eq 69 ]; then
        grug
        tput cup 0 0
        clear
    fi
    if cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null | grep -Eqi 'treeya|barla' 2>/dev/null; then
        echo -e "${RED_B}Barla/Treeya wifi unsupported. Please contact @kxtzownsu on discord${COLOR_RESET}"
    else
        signal=$(iw dev $wifidevice link | grep signal | awk '{print $2}' | sed 's/.00//' | head -1)
        if (( signal >= -50 )); then color=$'\e[1;38;5;82m'; strength=$'▃▅▇'
        elif (( signal >= -60 )); then color=$'\e[1;38;5;226m'; strength=$'▃▅\e[1;38;5;236m▇'
        elif (( signal >= -70 )); then color=$'\e[1;38;5;208m'; strength=$'▃\e[1;38;5;236m▅▇'
        else color=$'\e[1;38;5;196m'; strength=$'▃\e[1;38;5;236m▅▇'; fi
        ssid="$(iw dev "$wifidevice" link 2>/dev/null | awk -F ': ' '/SSID/ {print $2}')"
        if [ -f /etc/aftggp ]; then
            ssid="$ssid | ${CYAN_B}AFT running at: $(ip a | grep wlan0 | grep inet | awk '{print $2}' | sed 's|/.*||'):42069${COLOR_RESET}"
        fi
        if [ -n "$ssid" ]; then
            echo -e "\n${color}${strength}${color} $wifidevice${COLOR_RESET} $ssid" | center
        else
            echo -e "\n\e[1;38;5;196m▃\e[1;38;5;236m▅▇\e[1;38;5;196m $wifidevice${COLOR_RESET} disconnected" | center
        fi
    fi
    local width=42
	local verstring=${VERSION["STRING"]}
	local build=${VERSION["BUILDDATE"]}
	local version_pad=$(( (width - ${#verstring}) / 2 ))
    local build_pad=$(( (width - ${#build}) / 2 ))
    echo -ne "$CYAN_B"
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
    echo -ne "$CYAN_B"
    echo -e "\n$verstring" | center
    echo -e "$build" | center
    kernelver=$(getkv)
    if [ -f /etc/kernverpending ]; then
        kernelver=$(cat /etc/kernverpending)
        echo -e "$kernelver ${YELLOW_B}(pending reboot)${COLOR_RESET}" | center
    else
        echo -e "$kernelver" | center
    fi
    echo -e "\nhttps://github.com/EtherealWorkshop/Aurora" | center
	echo -e "Page ${page}${COLOR_RESET}" | center
    funText | center
}

##################
## MURKMOD SHIT ##
##################

lsbval() {
  local key="$1"
  local lsbfile="${2:-/etc/lsb-release}"

  if ! echo "${key}" | grep -Eq '^[a-zA-Z0-9_]+$'; then
    return 1
  fi

  sed -E -n -e \
    "/^[[:space:]]*${key}[[:space:]]*=/{
      s:^[^=]+=[[:space:]]*::
      s:[[:space:]]+$::
      p
    }" "${lsbfile}"
}

versions() {
    echo ""
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD 2>/dev/null)
    export board_name=${release_board%%-*}
    echo "What ChromeOS version do you want to download?" | center
	options_install=(
	    "Latest Version"
	    "Custom Version"
	)

	menu "Select an option (use ↑ ↓ arrows, Enter to select)" "${options_install[@]}"
	install_choice=$?

	case "$install_choice" in
	    0) chromeVersion="latest" ;;
	    1) stty echo
           read_center -d "Enter Version: " chromeVersion ;;
        *) fail "Invalid choice (somehow?????)" ;;
	esac
    echo "Fetching recovery image..." | center
    if [ $chromeVersion == "latest" ]; then
        builds="https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS"
        chromeVersion=$(curl -s $builds | jq -r ".builds.${board_name}.models | to_entries[0].value.servingStable.chromeVersion" | awk -F. '{print $1}')
        FINAL_URL=$(curl -s $builds | jq -r ".builds.${board_name}.models | to_entries[0].value.pushRecoveries[\"$chromeVersion\"]")
        if [ ! -n $FINAL_URL ]; then
            echo "Falling back to the most recent version found." | center
            FINAL_URL=$(curl -s $builds | jq ".builds.${board_name}.models | to_entries[0].value.pushRecoveries | to_entries | sort_by(.key | tonumber) | .[-1].value")
        fi
        [ -n "$chromeVersion" ] || fail "Failed finding Version"
        export chromeVersion
        export FINAL_URL
    else
        export url="https://raw.githubusercontent.com/MercuryWorkshop/chromeos-releases-data/refs/heads/main/data.json"
        cros_json=$(curl -s "$url" | jq --arg board "$board_name" --arg ver "$chromeVersion" '.[$board].images[] | select((.chrome_version | tostring) | test("^" + $ver))')
        if [[ -z "$cros_json" ]]; then return; fi
        cros_platform=$(echo "$cros_json" | jq -r '.platform_version'| head -1 )
        cros_url=$(echo "$cros_json" | jq -r '.url' | head -1 )
        last_modified=$(echo "$cros_json" | jq -r '.last_modified' | head -1 )
        MATCH_FOUND=0
        if [[ -n "$cros_url" ]]; then
            echo "Found a $chromeVersion match on platform $cros_platform from $last_modified." | center
            MATCH_FOUND=1
            export FINAL_URL="$cros_url"
            return 0
        fi
        if [ $MATCH_FOUND -eq 0 ]; then
            echo "No recovery image found for your board and target version. Exiting" | center
            return 1
        fi
    fi
}

#########################
## IMPORTANT FUNCTIONS ##
#########################

detect_aurora_in_shimboot_function() {
	echo "dD0oIkhlYXJzYXkhIiAiSSByZWZ1c2UuIiAiSSBzaGFsbCBkbyBubyBzdWNoIHRoaW5nISIgIkxpa2UuLi4gd2h5Pz8/IiAiSSBjZXJ0YWlubHkgd2lsbCBub3QhIiAiQXJlIHlvdSBqdXN0IGhlcmUgdG8gZGlsbHlkYWRkbGU/IiAiWW91IHJlYWxseSBoYXZlIG5vdGhpbmcgYmV0dGVyIHRvIGRvLCBkb24ndCB5b3U/IikKcz0ke3RbJFJBTkRPTSAlICR7I3RbQF19XX0KZWNobyAtZSAiICIKZWNobyAtZSAiJHMi" | base64 -d | bash | center
}

export_args() {
  local arg=
  local key=
  local val=
  local acceptable_set='[A-Za-z0-9]_'
  echo "Exporting kernel argument..." | center
  for arg in "$@"; do
    key=$(echo "${arg%%=*}" | busybox tr 'a-z' 'A-Z' | \
                   busybox tr -dc "$acceptable_set" '_')
    val="${arg#*=}"
    export "KERN_ARG_$key"="$val"
    echo -n " KERN_ARG_$key=$val,"
  done
  echo ""
}

export_args $(cat /proc/cmdline | sed -e 's/"[^"]*"/DROPPED/g') 1> /dev/null

copy_lsb() {
    echo "Copying lsb..." | center
    local src_path="/stateful/dev_image/etc/lsb-factory"
    local dest_path="/newroot/etc/lsb-factory"

    mkdir -p "$(dirname "${dest_path}")"

    if [ -f "${src_path}" ]; then
        echo "Found ${src_path}." | center
        cp "${src_path}" "${dest_path}" || fail "failed with $?"
        if cgpt find -l SH1MMER "${loop}" | head -n 1 | grep --color=never -q /dev/; then
            export specialshim="sh1mmer"
            echo "STATEFUL_DEV=${loop}p1" >> "${dest_path}"
        fi
        echo "REAL_USB_DEV=${loop}p3" >> "${dest_path}"
        echo "KERN_ARG_KERN_GUID=$(echo "${KERN_ARG_KERN_GUID}" | tr '[:lower:]' '[:upper:]')" >> "${dest_path}"
        echo "Copied lsb-factory to ${dest_path}" | center
    else
        fail "Missing ${src_path}!"
    fi
}


pv_dircopy() {
	[ -d "$1" ] || return 1
	local apparent_bytes
	apparent_bytes=$(du -sb "$1" | cut -f 1)
	mkdir -p "$2"
	tar -C /shimroot -cf - . | tar -C /newroot -xf -
}

############
## IMAGES ##
############

installcros() {
    chmod +x /usr/bin/bigtext
    bigtext installcros
	if [[ -z "$(ls -A $aroot/images/recovery 2>/dev/null)" ]]; then
        echo -ne "${YELLOW_B}"
		echo "You have no recovery images downloaded! Please download a few images" | center
		echo "Alternatively, these are available on websites such as chrome100.dev or cros.tech. Put them into /usr/share/aurora/images/recovery" | center
        read_center "Press Enter to return to the main menu"
        echo -ne "${COLOR_RESET}"
		return
	else
        mapfile -t recochoose < <(find "$aroot/images/recovery" -type f)
        reco_options=("${recochoose[@]}" "Exit")
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
    MOUNTS="/proc /dev /sys /tmp /run /var /mnt/stateful_partition"
    cd $recoroot
    d=
    for d in ${MOUNTS}; do
        mount -n --bind "${d}" "./${d}"
        mount --make-slave "./${d}"
    done
    chroot ./ /usr/sbin/chromeos-install --payload_image="${loop}" --yes || fail "Failed during chroot!" --fatal
    local cros_dev="$(get_largest_cros_blockdev)"
    cgpt add -i 2 $cros_dev -P 15 -T 15 -S 1 -R 1 || echo -e "${YELLOW_B}Failed to set kernel priority! Continuing anyway${COLOR_RESET}"
    clear
    source /usr/share/aurora/functions
    bigtext installcros
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
		echo "Alternatively, shims are available in https://github.com/EtherealWorkshop/[Sh1mmer, KVS, Aurora]/releases. Put them into /usr/share/aurora/images/shims" | center
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
        read_center -d "Reboot to boot into shimboot instead of Aurora from auroraboot? (Y/n): " bootshimboot
        case $bootshimboot in
            "n*"|"N*") return 0 ;;
            *) losetup -D
               
               reboot -f ;;
        esac
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
                parttype=$(udevadm info --query=property --name="$dev" 2>/dev/null | grep '^ID_PART_ENTRY_TYPE=' | cut -d= -f2)
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
        pivot_root /newroot /newroot/tmp/aurora
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

chromium() {
    apk add pcre-tools
    if [ ! -f /usr/sbin/setup-xorg-base ] && [ ! -f /usr/sbin/setup-devd ]; then
        mkdir -p "/tmp/apk-tools-static"
        wget -q --show-progress "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$(uname -m)/$(echo "$(wget -qO- --show-progress "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$(uname -m)/" | grep "apk-tools-static")" | pcregrep -o1 '"(.+?.apk)"')" -O "/tmp/apk-tools-static/pkg.apk"
        tar --warning=no-unknown-keyword -xzf "/tmp/apk-tools-static/pkg.apk" -C "/tmp/apk-tools-static"
        chmod +x /tmp/apk-tools-static/sbin/apk.static
        /tmp/apk-tools-static/sbin/apk.static --arch $(uname -m) -X http://dl-cdn.alpinelinux.org/alpine/edge/main/ -U --allow-untrusted --root "/" --initdb add alpine-base
        sync
    fi
    setup-xorg-base chromium gvfs font-dejavu openbox hsetroot
    rc-update add dbus sysinit
    openrc sysinit
    rm ~/.xinitrc
    cat <<EOF > ~/.xinitrc
openbox &
hsetroot -cover /usr/share/aurora/bg.png &
while true; do
    chromium --start-maximized --no-first-run --disable-infobars --disable-session-crashed-bubble --restore-last-session --no-sandbox
done
EOF
    killall frecon-lite
    startx
}

##################
## OPTIONS MENU ##
##################

payloads() {
    mapfile -t payloadchoose < <(find "$aroot/payloads" -maxdepth 1 -type f 2>/dev/null)
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

errormessage() {
    if [ -n "$errormsg" ]; then 
        echo -en "${RED_B}"
        echo "Error: ${errormsg}" | center
    fi
    echo -e "${COLOR_RESET}"
}

setupuser() {
    read_center -d "Username: " username
    stty -echo
    read_center -d "Password: " password
    stty echo 
    adduser -D "$username"
    echo "$username:$password" | chpasswd 2>/dev/null
    echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
    mkdir -p /run/user/$(id -u $username)
    chown $username:$username /run/user/$(id -u $username)
    usermod -aG video $username
    usermod -aG seat $username
}

setup() {
    tput cnorm
    stty echo
    if cat /etc/aurora | grep -q "setup=1"; then
        clear
        splash
        echo -e "\nSetup Aurora" | center
        read_center -d "Setup a user? (Y/n) " setupuser
        case $setupuser in
            n|N) ;;
            *) setupuser ;;
        esac
        while true; do
            read_center -d "Enter your timezone: " timezone
            timezone="*$(echo "$timezone" | sed 's/ /*/g')*"
            timezonefile=$(find /usr/share/zoneinfo -type f -iname "$timezone" | head -1)
            if [[ -z "$timezonefile" ]]; then echo "Invalid timezone" | center; continue; fi
            rm -rf /etc/localtime
            ln -s "$timezonefile" /etc/localtime
            break
        done
        read_center -d "Change Hostname? (y/N): " changehostname
        case $changehostname in
            y) read_center -d "Hostname: " hostname
               hostname $hostname
               echo "$hostname" > /etc/hostname
               echo "127.0.0.1 localhost $hostname" >> /etc/hosts ;;
            *) hostname Aurora
               echo "Aurora" > /etc/hostname
               echo "127.0.0.1 localhost Aurora" >> /etc/hosts ;;
        esac
        sed -i 's/setup=1/setup=0/' /etc/aurora
    fi
}

crosrun() { # sigh
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
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD 2>/dev/null)
    export board_name=${release_board%%-*}
    	options_download=(
	    "Sh1mmer Legacy - EtherealWorkshop/Sh1mmer/releases"
	    "Shimboot - ading2210/shimboot/releases"
        "Br0ker Sh1mmer - EtherealWorkshop/sh1mmer/actions"
        "Custom Shim from URL"
	)

	menu "Select an option (use ↑ ↓ arrows, Enter to select)" "${options_download[@]}"
	download_choice=$?

	case "$download_choice" in
	    0) export FINALSHIM_URL="https://github.com/EtherealWorkshop/sh1mmer/releases/download/v2.0.0/${board_name}.bin" ;;
	    1) export FINALSHIM_URL="https://github.com/ading2210/shimboot/releases/download/v1.3.0/shimboot_${board_name}.zip" ;;
        2) export FINALSHIM_URL="https://nightly.link/EtherealWorkshop/sh1mmer/actions/runs/17243134890/Br0ker%20Sh1mmer%20${board_name}.zip" ;;
	    3) tput cnorm
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
    if curl --head --silent --fail "$FINALSHIM_URL" >/dev/null; then
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
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"update-ca-certificates
    ntpd -q -p pool.ntp.org
    sync
    arch=$(uname -m)
    echo ""
    apk add git github-cli >/dev/null 2>&1
    if [ -d "/root/Aurora/.git" ]; then		
		if ! git -C "/root/Aurora" pull origin "$(cat /etc/aurora | grep origin | sed 's/origin=//')" 2>&1 | center; then
		    echo "git pull failed, recloning" | center
		    rm -rf /root/Aurora
        	git clone --branch=$(cat /etc/aurora | grep origin | sed 's/origin=//') https://github.com/EtherealWorkshop/Aurora /root/Aurora 2>&1 | center || return
		fi
    else
        [ -d "/root/Aurora" ] && rm -rf "/root/Aurora"
        git clone --branch=$(cat /etc/aurora | grep origin | sed 's/origin=//') https://github.com/EtherealWorkshop/Aurora /root/Aurora 2>&1 | center || return
    fi
    echo "Copying files to root..." | center
    updated=0
    if ! cmp -s /usr/share/aurora/aurora.sh /root/Aurora/rootfs/usr/share/aurora/aurora.sh 2>/dev/null; then
        updated=1
    fi
    cp -Lar /root/Aurora/rootfs/. /
    rm -rf /usr/share/patches/*
    mkdir -p /usr/share/patches/sh1mmer/
    mv /etc/aurora /etc/aurora.bak
    cp -Lar /root/Aurora/patches/sh1mmer/. /usr/share/patches/sh1mmer/
    mv /etc/aurora.bak /etc/aurora
    chmod +x /usr/share/aurora/* /usr/bin/* /sbin/init
    aurorabootmnt=$(mktemp -d)
    mount "$(lsblk -pro NAME,PARTLABEL,MOUNTPOINT | grep -i "AuroraBoot" | awk '{print $1}')" $aurorabootmnt
    cp -Lar /root/Aurora/auroraboot/. $aurorabootmnt/
    cp -Lar /root/Aurora/patches/shimboot/. $aurorabootmnt/
    chmod +x $aurorabootmnt/init $aurorabootmnt/bootstrap.sh $aurorabootmnt/sbin/init
    umount $aurorabootmnt
    if [ "$updated" = "1" ]; then
        echo "Restarting aurora.sh" | center
        sleep 3
        exec bash /usr/share/aurora/aurora.sh <${TTY1} >>${TTY1} 2>&1
    fi
}

aftggp() {
    tput cnorm
    apk add python3 py3-flask py3-bcrypt >/dev/null
    kill $(ps aux | grep "python3 /usr/share/ggp/" | grep -v grep | awk '{print $1}') 2>/dev/null
    rm -f /etc/aftggp
    read_center -d "Enter Password for AFT: " readpassword
    export readpassword
    python3 /usr/share/ggp/GGP.py > $LOGTTY 2>&1 &
    touch /etc/aftggp
}

connect() {
    ifconfig "$wifidevice" down
    pkill -12 udhcpc
    pkill udhcpc 2>/dev/null
    killall wpa_supplicant 2>/dev/null
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

    if grep -q "ssid=\"$ssid\"" "$conf" 2>/dev/null; then
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

    wpa_supplicant -B -i "$wifidevice" -c "$conf" >/dev/null

    for i in {1..15}; do
        if iw dev "$wifidevice" link | grep -q 'Connected'; then
            echo "Connected!" | center
            break
        fi
        sleep 1
    done

    if ! iw dev "$wifidevice" link | grep -q 'Connected'; then
        killall wpa_supplicant 2>/dev/null
        rm /etc/wpa_supplicant.conf
        return 1
    fi

    udhcpc -i "$wifidevice" 2>/dev/null || {
        return 1
    }
}

wifi() {
    chmod +x /usr/bin/bigtext
    bigtext wifi
    stty echo
    export wifidevice=$(ip link | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
    if cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null | grep -Eqi 'treeya|barla' 2>/dev/null; then
        fail "Barla/Treeya wifi unsupported. Please contact @kxtzownsu on discord"
    fi
    if iw dev "$wifidevice" link 2>/dev/null | grep -q 'Connected'; then
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
    "4. KVS"
)
menu2_actions=(
    "clear && script -qfc 'stty sane && stty erase '^H' && exec bash -l || exec busybox sh -l' /dev/null"
    "canwifi aftggp"
    "clear && canwifi aurorabuildenv"
    "clear && kvs"
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

    echo -e "[${GEEN_B}+${COLOR_RESET}] Starting udevd" | center
    /sbin/udevd --daemon | center || {
        echo -e "[${RED_B}-${COLOR_RESET}] Error: failed to start udevd" | center
        :
    }
    udevadm trigger | center || :
    udevadm settle | center || :
fi
printf '\033c' > $LOGTTY


for wifi in iwlwifi iwlmvm ccm 8021q rtw88 rtwpci ath10k_sdio mt7921e mt7921s mt76 rtw88_8822ce rtw8821ce rtw89pci; do
    modprobe -r "$wifi" 2>$LOGTTY || true
    modprobe "$wifi" 2>$LOGTTY
done
modprobe -a iwlwifi iwlmvm ccm 8021q rtw88 rtwpci ath10k_sdio mt7921e mt7921s mt76 rtw88_8822ce rtw8821ce rtw89pci 2>/dev/null
sleep 2
if [ -e "/etc/wpa_supplicant.conf" ]; then
    ls /etc/wpa_supplicant.conf >$LOGTTY 2>&1
    echo -e "[${GEEN_B}+${COLOR_RESET}] Connecting to wifi" | center
    export wifidevice=$(ip link | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
    ifconfig "$wifidevice" down
    pkill -12 udhcpc
    pkill udhcpc 2>/dev/null
    killall wpa_supplicant 2>/dev/null
    rm -rf /etc/*dhcpc*
    ifconfig "$wifidevice" up
	sleep 3
    if [ -n "$wifidevice" ]; then
				    wpa_supplicant -B -i "$wifidevice" -c /etc/wpa_supplicant.conf >"$LOGTTY" 2>&1
				else
				    echo -e "[${RED_B}-${COLOR_RESET}] Failed to find wifi device. Please connect manually." | center
				fi
    connected=0
    for i in $(seq 1 30); do
        if iw dev "$wifidevice" link 2>>"$LOGTTY" | grep -q 'Connected'; then
            if udhcpc -i "$wifidevice" >>"$LOGTTY" 2>&1; then
                connected=1
                echo "success on attempt $i" >>"$LOGTTY"
            else
                echo "failure on attempt $i" >>"$LOGTTY"
            fi
            break
        fi
        sleep 1
    done

    if [ $connected -eq 0 ]; then
        echo -e "[${RED_B}-${COLOR_RESET}] No nearby saved networks found" | center
    else
        updateshim
        sync
    fi
fi


release_board=$(lsbval CHROMEOS_RELEASE_BOARD 2>/dev/null)
export board_name=${release_board%%-*}
for chmod in /usr/bin/aurorabuildenv; do
    chmod +x $chmod
done
clear
export page=1 updatedpage=0
while true; do
	if ((page <= 0)); then
		export page=3
	elif ((page >= 4)); then
		export page=1
	fi
    export TERM=xterm-256color
    stty $stty
    eval "setup"
    clear
    hostname $(cat /etc/hostname)
    export wifidevice=$(ip link 2>/dev/null | grep -E "^[0-9]+: " | grep -oE '^[0-9]+: [^:]+' | awk '{print $2}' | grep -E '^wl' | head -n1)
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
