# ntp on ubuntu server

Ubuntu 24.04

```sh
sudo apt update 

sudo apt install systemd-timesyncd -y 

nano /etc/systemd/timesyncd.conf

NTP=172.17.20.1

NTP=time1.nimt.or.th

time2.nimt.or.th
time3.nimt.or.th
time4.nimt.or.th
time5.nimt.or.th


sudo systemctl enable systemd-timesyncd

sudo systemctl restart systemd-timesyncd

sudo systemctl status systemd-timesyncd
```
