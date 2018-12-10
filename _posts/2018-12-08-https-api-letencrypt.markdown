---
layout: post
title:  "Using LetsEncrypt to run an HTTPS server in q"
categories: kdb q https api
---

In a [previous post](https://jmcmurray.co.uk/kdb/q/rest/api/2018/05/22/rest-api-in-kdb.html)
I discussed creating an HTTP API in q. Back then I mentioned that I may explore
adding HTTPS support at a later point; I've recently had a chance to give this
a try, and thanks to [Let's Encrypt](https://letsencrypt.org/) it's very easy
to do!

This will work regardless of whether you are using the `webapi` library from my
previous post (now available from conda: `conda install -c jmcmurray webapi` -
see [this post](https://jmcmurray.co.uk/kdb/q/package/qutil/anaconda/conda/2018/07/16/q-package-management-with-conda.html)
about q package management for more details on that) or another custom
`.z.ph`/`.z.pp` definition (or even the default q HTTP interface).

Step one is to generate your certificates; this is pretty simple using certbot
from Let's Encrypt. This is a fairly straightforward process, documented
[here](https://certbot.eff.org/lets-encrypt/ubuntuartful-other) \[instructions
for various OSes available\]. For example on Ubuntu, once certbot is installed
we simply do something like:

```bash
sudo certbot certonly --standalone -d jmcmurray.hopto.org
```

(obviously `jmcmurray.hopto.org` is a domain I control). Certs will be
generated in e.g. `/etc/letsencrypt/live/jmcmurray.hopto.org`

```bash
jonny@grizzly ~ $ sudo ls -lFh /etc/letsencrypt/live/jmcmurray.hopto.org
total 4.0K
lrwxrwxrwx 1 root root  43 Oct 25 15:08 cert.pem -> ../../archive/jmcmurray.hopto.org/cert1.pem
lrwxrwxrwx 1 root root  44 Oct 25 15:08 chain.pem -> ../../archive/jmcmurray.hopto.org/chain1.pem
lrwxrwxrwx 1 root root  48 Oct 25 15:08 fullchain.pem -> ../../archive/jmcmurray.hopto.org/fullchain1.pem
lrwxrwxrwx 1 root root  41 Dec  8 14:10 jmcmurray.hopto.org -> /etc/letsencrypt/live/jmcmurray.hopto.org/
lrwxrwxrwx 1 root root  46 Oct 25 15:08 privkey.pem -> ../../archive/jmcmurray.hopto.org/privkey1.pem
-rw-r--r-- 1 root root 682 Oct 25 15:08 README
```

As the certs are created as root, we have a couple of options. We could run our
q server as root, allowing us to read the certs. Alternatively, we can copy (as
root) to another readable location e.g.

```bash
jonny@grizzly ~ $ mkdir certs
jonny@grizzly ~ $ sudo su
root@grizzly:/home/jonny# cp /etc/letsencrypt/live/jmcmurray.hopto.org/* certs/
cp: -r not specified; omitting directory '/etc/letsencrypt/live/jmcmurray.hopto.org/jmcmurray.hopto.org'
root@grizzly:/home/jonny# exit
exit
jonny@grizzly ~ $ ll certs/
total 20K
-rw-r--r-- 1 root root 2.2K Dec  8 15:06 cert.pem
-rw-r--r-- 1 root root 1.7K Dec  8 15:06 chain.pem
-rw-r--r-- 1 root root 3.8K Dec  8 15:06 fullchain.pem
-rw-r--r-- 1 root root 1.7K Dec  8 15:06 privkey.pem
-rw-r--r-- 1 root root  682 Dec  8 15:06 README
```

Now we can set the necessary environment variables & load up our q session:

```bash
jonny@grizzly ~ $ export SSL_CERT_FILE=~/certs/fullchain.pem
jonny@grizzly ~ $ export SSL_KEY_FILE=~/certs/privkey.pem
jonny@grizzly ~ $ q -E 1 -p 8100
KDB+ 3.6 2018.05.17 Copyright (C) 1993-2018 Kx Systems
l32/ 2()core 1944MB jonny grizzly 127.0.1.1 NONEXPIRE

q).utl.require"webapi"
q)\l git/qwebapi/example.q
```

(Here I load my `webapi` module previously mentioned & the same example script
I used in my previous post on HTTP APIs)

Now, we can query the API over HTTPS:

![HTTPS API]({{ "/assets/https_api.png" | absolute_url }})

All in all, the process is pretty simple & straightforward, and takes about 5
minutes. As a couple of closing notes:

* Using `-E 1` as I showed here still allows HTTP access; with `-E 2` only
HTTPS is allowed (however, HTTP requests will not be redirected to HTTPS - I'll
be looking into this in future)
* As per the [kx docs](https://code.kx.com/q/cookbook/ssl/#tls-server-mode)
`-u 1` should be used to prevent remote access to your server key file, & q
should not be run from a directory where the keys can be accessed

*UPDATE:* After publishing this post, I realised that kdb+ seemingly does not
publish the full certificate chain it is provided, only the server certificate.

This means that, when using Let's Encrypt, the intermediate LE certificate is
not provided to clients. Some clients (e.g. web browsers) will download the
intermediate(s) as necessary & the user will likely not notice anything is
"wrong". Other clients (e.g. another q session) will not, and will therefore
fail to verify the server certificate.

![HTTPS Chain]({{ "/assets/https-chain.png" | absolute_url }})
*Report from [SSL Labs](https://www.ssllabs.com/ssltest/index.html)*

In order to send an HTTPS query from another q session, you will need to either
disable SSL server verification (set env var `SSL_VERIFY_SERVER=NO` before
starting q) or add your server cert to the CA bundle you are using.
