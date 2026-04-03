#!/bin/bash
cd /root/checkin24hs
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
WEBMAIL_VIP=$(docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' 2>&1 | awk '{print $1}' | cut -d'/' -f1)
if [ -z "$WEBMAIL_VIP" ]; then
    WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
    if [ -n "$WEBMAIL_CONTAINER" ]; then
        EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
        WEBMAIL_VIP=$(docker inspect $WEBMAIL_CONTAINER --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "'$EASYPANEL_NET_NAME'"}}{{$conf.IPAddress}}{{end}}{{end}}' 2>&1)
    fi
fi
if [ -z "$WEBMAIL_VIP" ]; then
    exit 1
fi
CURRENT_SERVER=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>&1)
CURRENT_IP=$(echo $CURRENT_SERVER | cut -d':' -f1)
if [ "$CURRENT_IP" != "$WEBMAIL_VIP" ] && [ -n "$WEBMAIL_VIP" ]; then
    docker service update --label-add "traefik.http.services.webmail.loadbalancer.server=$WEBMAIL_VIP:80" checkin24hs_webmail >/dev/null 2>&1
    docker service update --force traefik >/dev/null 2>&1
fi
