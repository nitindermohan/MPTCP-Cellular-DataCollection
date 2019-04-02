# Raspberry Pi scripts for MPTCP data collection

The repository contains scripts for MPTCP data collection over two USB LTE interfaces. The kernel used in our setup was MPTCP v0.93 which is based on Linux Kernel v4.14. *However, the scripts will work for any kernel version.*

**The configuration of the system is as follows:**

 1. Raspberry Pi 2B+ running Raspbian. You can install MPTCP kernel over Raspbian by following [this](https://cnly.github.io/2018/06/11/building-and-installing-latest-mptcp-for-raspberry-pi.html) link.
 2. MPTCP-capable AWS server. The server runs Ubuntu 18.04 with Apache Web Server. You can directly install the kernel from MPTCP `apt` repository from instructions found [here](https://multipath-tcp.org/pmwiki.php/Users/AptRepository).
 3. Two LTE USB modems. We used a combination of TeleWell and D-Link modems.

The repository hosts two different test setups; **data transfers** and **video streaming over DASH** 

 - For Data transfer setup, you can add a sparse file for *X MB* size in a "Data" folder using the command `sudo dd if=/dev/zero of=X.img bs=X count=1`  where X can be `10M` for 10MB file.
 - For video transfer, you can set up a DASH server and host open-source video for streaming. One such dataset is available [here](https://dash.itec.aau.at/dash-dataset/).

# Directory Structure

> To be added

# Script Workflow

>To be added
