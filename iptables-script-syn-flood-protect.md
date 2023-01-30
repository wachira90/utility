# iptables script syn flood protect

````
#!/bin/bash

# Flush existing iptables rules
iptables -F

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow incoming SSH connections
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Limit incoming SYN packets to prevent SYN flood attack
iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT

# Drop all other incoming SYN packets
iptables -A INPUT -p tcp --syn -j DROP

# Allow all outgoing connections
iptables -A OUTPUT -j ACCEPT
````

This script will:

1. flush the existing iptables rules
2. allow established and related connections
3. allow incoming SSH connections
4. limit incoming SYN packets to 1 per second and accept
5. drop all other incoming SYN packets
6. allow all outgoing connections

It's important to note that this script is a simple example and may not be suitable for all use cases. You may need to adjust the rules based on your specific needs and requirements.

Please be aware that this script is not a complete solution and the rate limit of 1/s can be adjusted according to the capacity of your network. Also, it is important to have a monitoring system to detect and mitigate DDoS attack.
