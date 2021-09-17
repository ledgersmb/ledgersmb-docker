#!/bin/bash

cd /srv/ledgersmb

if [[ -n "$SSMTP_ROOT" ]]; then
    echo "\$SSMTP_ROOT set; parameter is deprecated and will be ignored"
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_FROMLINE_OVERRIDE" ]]; then
    echo "\$SSMTP_FROMLINE_OVERRIDE set; parameter is deprecated and will be ignored"
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_MAILHUB" ]]; then
    echo "\$SSMTP_MAILHUB set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPHOST" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPHOST setting from \$SSMTP_MAILHUB"
        LSMB_MAIL_SMTPHOST=${SSMTP_MAILHUB%:*}
    fi
    if [[ -z "$LSMB_MAIL_SMTPPORT" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPPORT setting from \$SSMTP_MAILHUB"
        LSMB_MAIL_SMTPPORT=${SSMTP_MAILHUB#*:}
    fi
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_HOSTNAME" ]]; then
    echo "\$SSMTP_HOSTNAME set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPSENDER_HOSTNAME" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPSENDER_HOSTNAME setting from \$SSMTP_HOSTNAME"
        LSMB_MAIL_SMTPSENDER_HOSTNAME=$SSMTP_HOSTNAME
    fi
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_USE_STARTTLS" ]]; then
    echo "\$SSMTP_USE_STARTTLS set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPTLS" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPSENDER_HOSTNAME setting from \$SSMTP_USE_STARTTLS"
        LSMB_MAIL_SMTPTLS=$SSMTP_USE_STARTTLS
    fi
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_AUTH_USER" ]]; then
    echo "\$SSMTP_AUTH_USER set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPUSER" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPUSER setting from \$SSMTP_AUTH_USER"
        LSMB_MAIL_SMTPUSER=$SSMTP_AUTH_USER
    fi
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_AUTH_PASS" ]]; then
    echo "\$SSMTP_AUTH_PASS set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPPASS" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPPASS setting from \$SSMTP_AUTH_PASS"
        LSMB_MAIL_SMTPPASS=$SSMTP_AUTH_PASS
    fi
    LSMB_HAVE_DEPRECATED=1
fi
if [[ -n "$SSMTP_AUTH_METHOD" ]]; then
    echo "\$SSMTP_AUTH_METHOD set; parameter is deprecated"
    if [[ -z "$LSMB_MAIL_SMTPAUTHMECH" ]]; then
        echo "  Deriving \$LSMB_MAIL_SMTPAUTHMECH setting from \$SSMTP_AUTH_METHOD"
        LSMB_MAIL_SMTPAUTHMECH=$SSMTP_AUTH_METHOD
    fi
    LSMB_HAVE_DEPRECATED=1
fi

if [[ -n "$LSMB_HAVE_DEPRECATED" ]]; then
    echo "!!! DEPRECATED \$SSMTP_* PARAMETERS WILL BE REMOVED in the 1.9 image!!!"
fi


if [[ ! -f ledgersmb.conf ]]; then
  cat <<EOF >/tmp/ledgersmb.conf
[main]
cache_templates = 1
[database]
host = $POSTGRES_HOST
port = $POSTGRES_PORT
default_db = $DEFAULT_DB
[mail]
${LSMB_MAIL_SMTPHOST:+smtphost=$LSMB_MAIL_SMTPHOST
}${LSMB_MAIL_SMTPPORT:+smtpport=$LSMB_MAIL_SMTPPORT
}${LSMB_MAIL_SMTPSENDER_HOSTNAME:+smtpsender_hostname=$LSMB_MAIL_SMTPSENDER_HOSTNAME
}${LSMB_MAIL_SMTPTLS:+smtptls=$LSMB_MAIL_SMTPTLS
}${LSMB_MAIL_SMTPUSER:+smtpuser=$LSMB_MAIL_SMTPUSER
}${LSMB_MAIL_SMTPPASS:+smtppass=$LSMB_MAIL_SMTPPASS
}${LSMB_MAIL_SMTPAUTHMECH:+smtpauthmech=$LSMB_MAIL_SMTPAUTHMECH
}
[proxy]
ip=${PROXY_IP:-172.17.0.1/16}
EOF
  export LSMB_CONFIG_FILE='/tmp/ledgersmb.conf'
fi

# start ledgersmb
# --preload-app allows application initialization to kill the entire
# starman instance (instead of just the worker, which will immediately
# get restarted) on error; it also has a positive effect on memory use

echo '--------- LEDGERSMB CONFIGURATION:  ledgersmb.conf'
cat ${LSMB_CONFIG_FILE:-ledgersmb.conf}
echo '--------- LEDGERSMB CONFIGURATION --- END'

# ':5762:' suppresses an uninitialized variable warning in starman
# the last colon means "don't connect using tls"; without it, there's a warning
exec starman --listen :5762: --workers ${LSMB_WORKERS:-5} \
             -I lib -I old/lib \
             --preload-app bin/ledgersmb-server.psgi
