#!/system/bin/sh

function usage()
{
    echo "Usage: ${0##*/} [--help] [--status] [ aosp | legacy | offload | sysbta ]" 1>&2
}

function which_resetprop_command()
{
    type resetprop 1>"/dev/null" 2>&1
    if [ $? -eq 0 ]; then
        echo "resetprop"
    else
        type resetprop_phh 1>"/dev/null" 2>&1
        if [ $? -eq 0 ]; then
            echo "resetprop_phh"
        else
            return 1
        fi
    fi
    return 0
}

function reloadAudioserver()
{
    # wait for system boot completion and audiosever boot up
    local i
    for i in `seq 1 3` ; do
        if [ "`getprop sys.boot_completed`" = "1"  -a  -n "`getprop init.svc.audioserver`" ]; then
            break
        fi
        sleep 0.9
    done

    if [ -n "`getprop init.svc.audioserver`" ]; then

        setprop ctl.restart audioserver
        sleep 0.2
        if [ "`getprop init.svc.audioserver`" != "running" ]; then
            # workaround for Android 12 old devices hanging up the audioserver after "setprop ctl.restart audioserver" is executed
            local pid="`getprop init.svc_debug_pid.audioserver`"
            if [ -n "$pid" ]; then
                kill -HUP $pid 1>"/dev/null" 2>&1
            fi
            for i in `seq 1 10` ; do
                sleep 0.2
                if [ "`getprop init.svc.audioserver`" = "running" ]; then
                    break
                elif [ $i -eq 10 ]; then
                    echo "audioserver reload failed!" 1>&2
                    return 1
                fi
            done
        fi
        return 0
        
    else
        echo "audioserver is not found!" 1>&2 
        return 1
    fi

}

function BluetoothHalStatus()
{
    if [ "`getprop persist.bluetooth.system_audio_hal.enabled`" = 1 ]; then
        echo "sysbta (\"sysbta\" HAL) : enabled" 1>&2
        
    else
        if [ "`getprop persist.bluetooth.bluetooth_audio_hal.disabled`" != "true"  -a  -r "/vendor/lib64/hw/audio.bluetooth.default.so" ]; then
            echo "aosp (\"bluetooth\" HAL) : enabled" 1>&2
        elif [ -r "/system/lib64/hw/audio.a2dp.default.so"  -o  -r "/system/lib/hw/audio.a2dp.default.so" ]; then
            echo "a2dp (\"a2dp\" HAL) : enabled" 1>&2
        elif [ -r "/vendor/lib64/hw/audio.bluetooth_qti.default.so"  -o  -r "/vendor/lib/hw/audio.bluetooth_qti.default.so" ]; then
            echo "qti (\"bluetooth_qti\" HAL) : enabled" 1>&2
        fi
        
        if [ "`getprop ro.bluetooth.a2dp_offload.supported`" = "true"  -a  "`getprop persist.bluetooth.a2dp_offload.disabled`" = "false" ]; then
            echo "offload (\"primary.$(getprop ro.board.platform)\" a2dp offload HAL) : enabled" 1>&2
        fi
        
    fi
}

BTmode="aosp"

if [ $# -eq 1 ]; then
    case "$1" in
        "aosp" | "legacy" | "offload" | "sysbta" )
            BTmode="$1"
            ;;
        "-s" | "--status" )
            BluetoothHalStatus
            exit 0
            ;;
        "-h" | "--help" )
            usage
            exit 0
            ;;
        -* | * )
            usage
            exit 1
            ;;
    esac
else
    usage
    exit 0
fi

resetprop_command="`which_resetprop_command`"
if [ -z "$resetprop_command" ]; then
    echo "${0##*/} cannot change Bluetooth HAL; (no resetprop commands found)" 1>&2
    exit 1
fi

if [ -n "`getprop persist.bluetooth.system_audio_hal.enabled`" ]; then
    if [ "$BTmode" = "sysbta" ]; then
        setprop persist.bluetooth.bluetooth_audio_hal.disabled false
        setprop persist.bluetooth.a2dp_offload.disabled true
        "$resetprop_command" ro.bluetooth.a2dp_offload.supported false
        setprop persist.bluetooth.system_audio_hal.enabled 1
    else
        "$resetprop_command" --delete persist.bluetooth.bluetooth_audio_hal.disabled
        "$resetprop_command" --delete persist.bluetooth.a2dp_offload.disabled
        "$resetprop_command" --delete ro.bluetooth.a2dp_offload.supported
        setprop persist.bluetooth.system_audio_hal.enabled 0
    fi
fi

case "$BTmode" in
    "aosp" )
        if [ -r "/vendor/lib64/hw/audio.bluetooth.default.so"  -o   -r "/vendor/lib/hw/audio.bluetooth.default.so" ]; then
            setprop persist.bluetooth.bluetooth_audio_hal.disabled false
         else
            echo "${0##*/} cannot change to \"${BTmode}\"; (no ${BTmode} HAL module)" 1>&2
            exit 1
         fi
        ;;
    "legacy" )
        if [ -r "/system/lib64/hw/audio.a2dp.default.so"  -o   -r "/system/lib/hw/audio.a2dp.default.so" ]; then
            setprop persist.bluetooth.bluetooth_audio_hal.disabled true
        else
            echo "${0##*/} cannot change to \"${BTmode}\"; (no ${BTmode} HAL module)" 1>&2
            exit 1
        fi
        ;;
    "offload" )
        if [ -n "`getprop persist.bluetooth.a2dp_offload.cap`" ]; then
            reloadAudioserver
            setprop persist.bluetooth.bluetooth_audio_hal.disabled false
            setprop persist.bluetooth.a2dp_offload.disabled false
            "$resetprop_command" ro.bluetooth.a2dp_offload.supported true
            stop vendor.audio-hal
            stop system.bt-audio-hal
            start vendor.audio-hal
        else
            echo "${0##*/} cannot change to \"${BTmode}\"; (no ${BTmode} HAL module)" 1>&2
            exit 1
        fi
        ;;
    "sysbta" )
        if [ -z "`getprop persist.bluetooth.system_audio_hal.enabled`" ]; then
            echo "${0##*/} cannot change to \"${BTmode}\"; (no ${BTmode} HAL module)" 1>&2
            exit 1
        fi
        ;;
esac

if [ "$BTmode" != "offload" ]; then
    if [ "`getprop init.svc.system.bt-audio-hal`" = "stopped" ]; then
        start system.bt-audio-hal
    fi

    reloadAudioserver
    
fi
BluetoothHalStatus
exit 0
