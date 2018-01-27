# aggregate-ipaddr
Tools for aggregate IP address blocks which fetched from all Regional Internet Registries.

## usage
run `create-aggregated-ipaddrs.sh` then `/tmp/aggregate-ipaddr/aggregated-ipaddrs.txt` is created.

## aggregated-ipaddrs.txt
The format of line is:

```
<Country Code>\t<IP Address>/<CIDR>
```

Each IP address and CIDR are aggregated into the largest possible block. eg:

`delegated-RIR-extended-latest` fetched from each RIRs is enumerated following:

```
256 addresses from 192.168.0.0
256 addresses from 192.168.1.0
256 addresses from 192.168.2.0
256 addresses from 192.168.3.0
```

`aggregate-ipaddr.pl` aggregates to:

```
192.168.0.0/22
```

And `delegated-RIR-extended-latest` has like following also:

```
6144 addresses from 192.168.0.0
```

`aggregate-ipaddr.pl` divides to:

```
192.168.0.0/20
192.168.16.0/21
```

## note
Change command path variables in `create-aggregated-ipaddrs.sh` for your distribution. (The default variables is set for Arch Linux.)

### For Gentoo

```
MKDIR_BIN='/bin/mkdir'
PERL_BIN='/usr/bin/perl'
CURL_BIN='/usr/bin/curl'
```
