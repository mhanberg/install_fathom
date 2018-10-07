# Install Fathom

Single command install of [Fathom Analytics](https://github.com/usefathom/fathom).

This script administers:

- Fathom server running on port 9000.
- NGINX reverse proxy server using your domain name.
- HTTPS using [certbot](https://certbot.eff.org/) provided by [Let's Encrypt](https://letsencrypt.org/).
- Enables Fathom has a service using [systemd](https://en.wikipedia.org/wiki/Systemd).

## Usage

```bash
sudo bash <(curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/mhanberg/install_fathom/master/install_fathom.sh)
```

## Disclaimer

This has only been tested on a Digital Ocean Ubuntu 18.04 droplet.
