#!/bin/sh
DATE=`date +%Y%m%d`;
cd /tmp;
rm -rf abhayapower-$DATE;
cp -rf /opt/abhayapower abhayapower-$DATE;
mkdir /tmp/abhayapower-$DATE/etc/;
cp /etc/abhayapower abhayapower-$DATE/etc/abhayapower;
chown -R abhayapower:abhayapower abhayapower-$DATE;
tar zcf abhayapower-$DATE.tgz abhayapower-$DATE;
chown abhayapower:abhayapower abhayapower-$DATE.tgz;
rm -rf abhayapower-$DATE;

cp abhayapower-$DATE.tgz "$1";
