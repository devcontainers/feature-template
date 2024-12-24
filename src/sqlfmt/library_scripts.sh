

clean_download() {
    # The purpose of this function is to download a file with minimal impact on container layer size
    # this means if no valid downloader is found (curl or wget) then we install a downloader (currently wget) in a
    # temporary manner, and making sure to
    # 1. uninstall the downloader at the return of the function
    # 2. revert back any changes to the package installer database/cache (for example apt-get lists)
    # The above steps will minimize the leftovers being created while installing the downloader
    # Supported distros:
    #  debian/ubuntu/alpine

    url=$1
    output_location=$2
    tempdir=$(mktemp -d)
    downloader_installed=""

    _apt_get_install() {
        tempdir=$1

        # copy current state of apt list - in order to revert back later (minimize contianer layer size)
        cp -p -R /var/lib/apt/lists $tempdir
        apt-get update -y
        apt-get -y install --no-install-recommends wget ca-certificates
    }

    _apt_get_cleanup() {
        tempdir=$1

        echo "removing wget"
        apt-get -y purge wget --auto-remove

        echo "revert back apt lists"
        rm -rf /var/lib/apt/lists/*
        rm -r /var/lib/apt/lists && mv $tempdir/lists /var/lib/apt/lists
    }

    _apk_install() {
        tempdir=$1
        # copy current state of apk cache - in order to revert back later (minimize contianer layer size)
        cp -p -R /var/cache/apk $tempdir

        apk add --no-cache  wget
    }

    _apk_cleanup() {
        tempdir=$1

        echo "removing wget"
        apk del wget
    }
    # try to use either wget or curl if one of them already installer
    if type curl >/dev/null 2>&1; then
        downloader=curl
    elif type wget >/dev/null 2>&1; then
        downloader=wget
    else
        downloader=""
    fi

    # in case none of them is installed, install wget temporarly
    if [ -z $downloader ] ; then
        if [ -x "/usr/bin/apt-get" ] ; then
            _apt_get_install $tempdir
        elif [ -x "/sbin/apk" ] ; then
            _apk_install $tempdir
        else
            echo "distro not supported"
            exit 1
        fi
        downloader="wget"
        downloader_installed="true"
    fi

    if [ $downloader = "wget" ] ; then
        wget -q $url -O $output_location
    else
        curl -sfL $url -o $output_location
    fi

    # NOTE: the cleanup procedure was not implemented using `trap X RETURN` only because
    # alpine lack bash, and RETURN is not a valid signal under sh shell
    if ! [ -z $downloader_installed  ] ; then
        if [ -x "/usr/bin/apt-get" ] ; then
            _apt_get_cleanup $tempdir
        elif [ -x "/sbin/apk" ] ; then
            _apk_cleanup $tempdir
        else
            echo "distro not supported"
            exit 1
        fi
    fi

}



ensure_nanolayer() {
    # Ensure existance of the nanolayer cli program
    local variable_name=$1

    local required_version=$2

    local __nanolayer_location=""

    # If possible - try to use an already installed nanolayer
    if [ -z "${NANOLAYER_FORCE_CLI_INSTALLATION}" ]; then
        if [ -z "${NANOLAYER_CLI_LOCATION}" ]; then
            if type nanolayer >/dev/null 2>&1; then
                echo "Found a pre-existing nanolayer in PATH"
                __nanolayer_location=nanolayer
            fi
        elif [ -f "${NANOLAYER_CLI_LOCATION}" ] && [ -x "${NANOLAYER_CLI_LOCATION}" ] ; then
            __nanolayer_location=${NANOLAYER_CLI_LOCATION}
            echo "Found a pre-existing nanolayer which were given in env variable: $__nanolayer_location"
        fi

        # make sure its of the required version
        if ! [ -z "${__nanolayer_location}" ]; then
            local current_version
            current_version=$($__nanolayer_location --version)


            if ! [ $current_version == $required_version ]; then
                echo "skipping usage of pre-existing nanolayer. (required version $required_version does not match existing version $current_version)"
                __nanolayer_location=""
            fi
        fi

    fi

    # If not previuse installation found, download it temporarly and delete at the end of the script
    if [ -z "${__nanolayer_location}" ]; then

        if [ "$(uname -sm)" = 'Linux x86_64' ] || [ "$(uname -sm)" = "Linux aarch64" ]; then
            tmp_dir=$(mktemp -d -t nanolayer-XXXXXXXXXX)

            clean_up () {
                ARG=$?
                rm -rf $tmp_dir
                exit $ARG
            }
            trap clean_up EXIT


            if [ -x "/sbin/apk" ] ; then
                clib_type=musl
            else
                clib_type=gnu
            fi

            tar_filename=nanolayer-"$(uname -m)"-unknown-linux-$clib_type.tgz

            # clean download will minimize leftover in case a downloaderlike wget or curl need to be installed
            clean_download https://github.com/devcontainers-extra/nanolayer/releases/download/$required_version/$tar_filename $tmp_dir/$tar_filename

            tar xfzv $tmp_dir/$tar_filename -C "$tmp_dir"
            chmod a+x $tmp_dir/nanolayer
            __nanolayer_location=$tmp_dir/nanolayer


        else
            echo "No binaries compiled for non-x86-linux architectures yet: $(uname -m)"
            exit 1
        fi
    fi

    # Expose outside the resolved location
    export ${variable_name}=$__nanolayer_location

}