# docker-hosts-provider

Make your docker containers accesible over local DNS.

## What does it do?

This service iterates over docker containers that have a macvlan network and container_name assigned to them, and exposes hosts-file that can be used with [CoreDNS](https://github.com/coredns/coredns).

## Prerquisites

Create a Docker macvlan network

```bash
# this is just an example, adapt to your needs
$ docker network create -d macvlan --subnet=10.1.30.0/24 --gateway=10.1.30.1 -o parent=eth0.30  vlan.30
```

## Usage

### docker-compose.yaml

```yaml
docker-dns-monitor:
  container_name: docker-dns-monitor
  image: ghcr.io/ad-on-is/docker-hosts-provider
  restart: always
  environment:
    - DOMAIN=home.arpa # use your prefered local DNS (homelab.lan, my.home, etc...)
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /path/to/geneated/hosts:/etc/docker_hosts

coredns:
  image: coredns/coredns
  container_name: coredns
  restart: always
  ports:
    - 53:53
    - 53:53/udp
  volumes:
    - ./Corefile:/Corefile
    - /path/to/geneated/hosts:/etc/coredns/hosts
  command: -conf /Corefile

example-container:
  image: nginx
  container_name: web
  networks:
    vlan.30:
      ipv4_address: 10.1.30.20 # (optional)

networks:
  vlan.30:
    external: true
```

### Corefile

To use with CoreDNS

```
. {
    log
    errors
    debug
    health
    ready
    hosts /etc/coredns/hosts {
        reload 10s
        fallthrough
    }
    cache 30
    reload
    loadbalance
}
```

## DNS/PTR entries

To make it actually work, you need to tell your DNS-server (router, pihole, etc...) about CoreDNS and the subnet-range to look for the DNS/PTR entries.

If your LAN spans from 10.1.0.0 to 10.1.255.255, and CoreDNS runs on 10.1.0.2, this is what you'd do

### dnsmasq.conf

```bash
# this is just an example, adapt to your needs
server=/1.10.in-addr.arpa/10.1.0.2
```

## Verify it works

Execute the following commands on a machine that is within your network.

```bash
$ ping web.home.arpa
# PING web.home.arpa (10.1.30.20) 56(84) bytes of data.
# 64 bytes from web.home.arpa (10.1.30.20): icmp_seq=1 ttl=64 time=0.182 ms

$ dig -x 10.1.30.20
# ...
# ;; ANSWER SECTION:
# 20.30.1.10.in-addr.arpa. 3600	IN	PTR	web.home.arpa.
# ...

```
