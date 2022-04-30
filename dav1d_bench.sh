function usage()
{
   cat << HEREDOC

   Usage: $0 [--version VERSION]

   optional arguments:

     -h, --help         Show this help message and exit

     -v, --version      Specify dav1d version for running test.
                        Supported versions: 0.5.2, 0.8.2, 0.9.2, 0.9.3-git-6aaeeea6 and 1.0.0.
                        By default is using version 0.9.3-git-6aaeeea6.

HEREDOC
}

## Print help if no args passed
# if [ "$#" -eq 0 ]; then
#     usage >&2
#     exit 1
# fi

dav1dversion="0.9.3-git-6aaeeea6";

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit ;;
        -v|--version) dav1dversion="$2"; shift ;;
        *) echo "Unknown parameter passed: $1" ;;
    esac
    shift
done

if [[ $(arch) =~ ^(arm|aarch64) ]]; then
    if [[ $OSTYPE =~ ^linux ]]; then
        if [[ -f /usr/bin/exagear ]]; then
            translator="exagear";
            translatorargs=" -- ";
            function transver() { echo "ExaGear version: $(/opt/exagear/bin/ubt_x64a64_opt --version | grep -i Revision)"; };
        fi;
    elif [[ $OSTYPE =~ ^darwin ]]; then
        translator="arch";
        translatorargs="-x86_64";
    else
        if [[ $(ps -p $$ | awk '{print $4}' | tail -n 1) =~ zsh ]]; then
            echo '?Trying to run on unsupported platform.';
            return 1 2>/dev/null;
        else
            while true; do
                read -s -n 1 -p "Unsupported platform. Press Ctrl+C to quit.";
            done;
        fi;
    fi;
fi;
if [[  $(arch) =~ ^e2k ]]; then
    translator="/opt/mcst/rtc/bin/rtc_opt_rel_p1_x64_ob";
    translatorargs="--path_prefix /mnt/shared/rtc/ubuntu20.04/ -b $HOME -b /etc/passwd -b /etc/group -b /etc/resolv.conf --";
    function transver() { /opt/mcst/rtc/bin/rtc_opt_rel_p1_x64_ob --version | egrep -o "^.*lcc\s?[a-Z0-9.]*" };
fi;

if [[ ! $(nproc) || $(nproc) == "" || $(nproc) -le 0 ]];
    then cputhreads=$(getconf _NPROCESSORS_ONLN);
else
    cputhreads=$(nproc);
fi;
if [[ $dav1dversion =~ ^(0\.9\.3-git|1\.) ]]; then
    threads="--threads $cputhreads";
else
    if [[ $cputhreads -ge 2 ]]; then
        threads="--framethreads $cputhreads --tilethreads $(( $cputhreads / 2 ))";
    else
        threads="--framethreads 1 --tilethreads 1";
    fi;
fi;

postargs="-o - $threads --muxer=null";
translate="";
folder1="";
folder2="x86_64";

if [[ ! $(arch) =~ ^((x|i[[:digit:]])86|amd64) ]]; then
    declare -a folders=("$folder1" "$folder2");
else
    declare -a folders=("$folder1");
fi;
for folder in "${folders[@]}"; do
    cd ./$folder;
    if [[ $folder == $folder1 ]]; then
        translate="";
        Mode="Native";
        if [[ $(arch) == "e2k" ]]; then
            declare -a buildargsarr=("" "-O3" "-O4");
        elif [[ $(arch) =~ ^(arm|aarch64) ]]; then
            buildargsarr=("" "-O3" "-asm");
        fi;
    else
        echo ;
        if [[ $(type -t transver) == function ]]; then
            transver;
        fi;
        translate="$translator $translatorargs";
        Mode="Translate";
        declare -a buildargsarr=("" "-O3" "-asm");
    fi;
    for buildargs in "${buildargsarr[@]}"; do
        dav1d="dav1d-$dav1dversion$buildargs/build/tools/dav1d";
        echo ;
        eval $translate ./$dav1d --version;
        for testvideo in "Chimera-2397fps-AV1-10bit-1920x1080-3365kbps.obu" "Chimera-AV1-8bit-1920x1080-6736kbps.ivf" "Chimera-AV1-10bit-1920x1080-6191kbps.ivf"; do
            if [[ $OSTYPE =~ ^linux.* ]]; then
                /usr/bin/time -f "Elapsed: %E (%e secs). Mode: $Mode. dav1d$buildargs. Threads: $cputhreads. Video: $testvideo" /bin/bash -c "eval $translate ./$dav1d -i ./$testvideo $postargs &>/dev/null";
            else
                shell="bash";
                if [[ $(ps -p $$ | awk '{print $4}' | tail -n 1) =~ .*zsh ]]; then
                    shell="zsh";
                fi;
                /usr/bin/time /bin/$shell -c "eval $translate ./$dav1d -i ./$testvideo $postargs &>/dev/null";
            fi;
        done;
    done;
    if [[ $folder != "" ]]; then
        cd ../;
    fi;
done
