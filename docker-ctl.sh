#!/usr/bin/env bash

install-plugins() {
    echo "installing plugins: $@"
    for PLUGIN in "${@}"; do
        sensu-install -p "$PLUGIN" --no-ri --no-rdoc
        EXIT_CODE="$?"
        if [ $EXIT_CODE -ne 0 ]; then
            echo "Failed to install plugin $PLUGIN"
            return $EXIT_CODE
        fi
    done
    return 0
}

run-component() {
    if [ "server" != "$1" ] && [ "client" != "$1" ] && [ "api" != "$1" ]; then
        echo "Usage: run (server|client|api)"
        return 1
    fi

    # todo ensure export is really necessary
    export SENSU_LOG_LEVEL=${SENSU_LOG_LEVEL:=debug}
    export SENSU_CONFIGURATION_DIRECTORY=${SENSU_CONFIGURATION_DIRECTORY:=/etc/sensu/conf.d}
    export SENSU_CONFIGURATION_FILE=${SENSU_CONFIGURATION_FILE:=/etc/sensu/config.json}
    export SENSU_TRANSPORT_NAME=${SENSU_TRANSPORT_NAME:=rabbitmq}
    export SENSU_EXTENSIONS_DIRECTORY=${SENSU_EXTENSIONS_DIRECTORY:=/etc/sensu/extensions}

    export SENSU_API_PORT=${SENSU_API_PORT:=80}

    if [ -z "$RABBITMQ_URL" ]; then
        if [ ! -z "$SENSU_AMQP_URL" ]; then
            RABBITMQ_URL="$SENSU_AMQP_URL"
        elif [ ! -z "$SENSU_RABBITMQ_URL" ]; then
            RABBITMQ_URL="$SENSU_RABBITMQ_URL"
        fi
    fi
    if [ -z "$REDIS_URL" ] && [ ! -z "$SENSU_REDIS_URL" ]; then
        export REDIS_URL="$SENSU_REDIS_URL"
    fi
    if [ -z "$PLUGINS_DIR" ] && [ ! -z "$SENSU_PLUGINS_DIRECTORY" ]; then
        export PLUGINS_DIR="$SENSU_PLUGINS_DIRECTORY"
    fi
    if [ -z "$HANDLERS_DIR" ] && [ ! -z "$SENSU_HANDLERS_DIRECTORY" ]; then
        export HANDLERS_DIR="$SENSU_HANDLERS_DIRECTORY"
    fi
    if [ -z "$USER" ] && [ ! -z "$SENSU_USER" ]; then
        export USER="$SENSU_USER"
    fi
    if [ -z "$SERVICE_MAX_WAIT" ] && [ ! -z "$SENSU_LAUNCH_TIMEOUT" ]; then
        export SERVICE_MAX_WAIT="$SENSU_LAUNCH_TIMEOUT"
    fi

    if [ ! -z "$SENSU_PLUGINS" ]; then
        install-plugins $SENSU_PLUGINS
    fi

    VERBOSITY_FLAG=""
    if [ ! -z "$SENSU_VERBOSE_LOGGING" ]; then
        VERBOSITY_FLAG="-v"
    fi

    exec sensu-$1 -L $SENSU_LOG_LEVEL \
        -d $SENSU_CONFIGURATION_DIRECTORY -c $SENSU_CONFIGURATION_FILE \
        -e $SENSU_EXTENSIONS_DIRECTORY \
        $VERBOSITY_FLAG
}

case $1 in
"install-plugins")
    exit $(install-plugins "${@:2}")
;;
"run")
    if [ "server" != "$2" ] && [ "client" != "$2" ] && [ "api" != "$2" ]; then
        echo "Usage: $0 run (server|client|api)"
        exit 1
    fi
    run-component $2
;;
*)
echo "Usage:"
echo
echo "  Install plugins:"
echo "  $0 install-plugins (plugin list: ponymailer docker...)"
echo
echo "  Run specific component:"
echo "  $0 run (server|client|api)"
;;
esac