# Dockerized Wordpress with SSL

Deploys Wordpress behind a Nginx proxy. Uses Certbot to get the SSL certificate

## Requesting the SSL certificate
This step only has to be executed once, to get the initial SSL certificate:
1. Edit the [site.conf](./nginx/conf/site.conf) and replace `[domain-name]` with your actual domain name
1. Run `docker compose up -d` to start the components
1. Test requesting a certificate:
```
docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d [domain-name]
```
1. If the request works, re-run the command without the `--dry-run` flag

## Starting the HTTPS website
The Nginx webserver will pick up the certificate retrived by Certbot
1. Edit the [site.conf](./nginx/conf/site.conf) and uncomment the SSL configuration block
1. Restart Nginx running `docker compose restart webserver`

## Renewing the certificate
Let's Encrypt certificates last for 3 months, after which it is necessary to renew them. To renew certificates, execute the following command:
```
docker compose run --rm certbot renew
```
