# bind-cookbook

**NOT ACTUALLY TESTED OUTSIDE OF TEST-KITCHEN YET**

Prototype cookbook to automatically configure bind and generate zone files based
on data bags. Uses a staging file to determin if zone has changed and rolls the
serial accordingly.

Some record types, like SRV and MX have more options, like weight and priority,
if they are not present when used it will fail to verify the zone, and therefor
not reload it. No tailing dots required.

Supported record types:
  - A
  - AAAA
  - TXT
  - SRV
  - CNAME / DNAME
  - MX

## Supported Platforms

- Debian 8.4

## Dependencies

- chef-sugar

## TODO

- A lot more testing
- Add support for DNSSEC (might involve some manual steps)
- ACLs
  - Recursive name servers
  - DDNS support using rdnc
- LWRP
  - Using DDNS to update records
- Add role for local DNS-server
  - DDNS with rdnc for DHCP-servers

## Usage

Makes the assumption that you run one master with the role `NS-master` and
slaves with `NS-slave`.

`NS-slave` will fail to start if there is no master present. Either provision
`NS-master` first or let `NS-slave` pick up the master when it's done.

Consistent eventually! Or something...

### bind::default
Installs and configures bind. Used in both `NS-master` and `NS-slave` roles.

### bind::master
Configures and generates zones based on data bags. Also stages a file for each
zone on the master that contains a digest of all zone data. When zone updates it
triggers a regeneration of the zone file and reload.

## Kitchen
Makes some (probably bad) assumptions about IP-allocations to go around the
limitations of test-kitchen and multiple nodes. Using hostonly networking, so
they are currently not reachable from the host.

`NS-master` listens to `192.168.100.10` and is configured on the suite `master`.

`NS-slave` listens to `192.168.100.20` and is configured on the suite `slave`

There is also very basic testing set up that currently only checks if bind has
been installed and is running on a specific port.

## Data Bags

Most of the fields are pretty self explanatory. The array `roles` specify what
roles it should search for when adding other hosts hostname and ipaddress.
Currently only IPv4 support.

Uses one data bag item per zone.

```json
{
  "id": "integrationtesting",
  "fqdn": "integrationtesting.local",
  "globals": {
    "ttl": "300",
    "soa": "ns1.integrationtesting.local",
    "contact": "abuse.integrationtesting.local",
    "nameservers": [
      "ns1.integrationtesting.local",
      "ns2.integrationtesting.local"
    ]
  },
  "records": [
    {
      "hostname": "ns1",
      "type": "A",
      "ttl": "600",
      "value": "192.168.100.10"
    }
  ],
  "roles": ["Server"]
}
```
