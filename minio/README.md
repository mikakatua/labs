# MinIO
## Binary installation
Installation guide:
[Deploy MinIO in Distributed Mode](https://docs.min.io/minio/baremetal/installation/deploy-minio-distributed.html)
```
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin/minio
```

## Disk setup
```
mkdir /mnt/disk{1..4}

mkfs.xfs /dev/sdc -L DISK1
mkfs.xfs /dev/sdd -L DISK2
mkfs.xfs /dev/sde -L DISK3
mkfs.xfs /dev/sdf -L DISK4

cat <<! >> /etc/fstab
LABEL=DISK1      /mnt/disk1     xfs     defaults,noatime  0       2
LABEL=DISK2      /mnt/disk2     xfs     defaults,noatime  0       2
LABEL=DISK3      /mnt/disk3     xfs     defaults,noatime  0       2
LABEL=DISK4      /mnt/disk4     xfs     defaults,noatime  0       2
!

mount -a
```

## User setup
```
groupadd -r minio-user
useradd -m -r -g minio-user minio-user
chown minio-user:minio-user /mnt/disk1 /mnt/disk2 /mnt/disk3 /mnt/disk4
```
Install the certificates:
```
/home/minio-user/.minio/certs
├── CAs
│   └── ca.crt
├── private.key
└── public.crt
```

## Service setup
Create the files
* /etc/default/minio
* /etc/systemd/system/minio.service

## Load balancer setup
Create the config file `/etc/nginx/sites-enabled/minio`
```
rm /etc/nginx/sites-enabled/default
ln -s ../sites-available/minio /etc/nginx/sites-enabled/
```
Install the certificates:
* /etc/ssl/minio.localnet.chained.crt
* /etc/ssl/minio.localnet.key


