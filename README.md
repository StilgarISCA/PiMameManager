# Pi Mame Manager

**TLDR;**

A Perl script for Raspbian OS to help facilitate the use of a Raspberry Pi as a replica arcade cabinet.

This was built for my replica Track & Field cocktail project, which you can read more about at [http://www.classicarcadeprojects.com](http://www.classicarcadeprojects.com/?utm_source=github&utm_medium=code&utm_content=group&utm_campaign=code).
## More Details

### The Problem
The problem is Raspberry Pis need to be powered down properly to avoid corrupting the file system. A fair number of arcade machines were designed to operate just by pulling the plug so it's difficult to simulate this functionality with a Raspberry Pi.

### The Solution
Using a USB power brick (like you'd use as backup power for your cell phone) combined with an ethernet switch, and this script, we can create a makeshift Uninterruptible Power Supply (UPS).

The script is responsible for detecting the power state and launching or killing Mame as appropriate.

To achieve this, the script watches connectivity of the Raspberry Pi's ethernet port. When power is dropped, the ethernet switch will lose power and the script will detect the lost of network connectivity on the ethernet port.

The script will stop Mame from running when the power fails. It will also track the amount of downtime and compare that against the expected battery life for the backup battery. If the threshold of the backup battery is exceeded the script will shutdown the Pi.

### How To Use
Clone or copy the script to your computer, grant executable access (`chmod +x pi-mame-manager.pl`) and then run from the terminal to get started `./pi-mame-manager.pl`.

There are some global variables defined at the beginning of the code which you will need to modify based on your needs: your path to Mame, the name of your Mame executable, the game you want to run, etc.

The script runs in a loop, so you can execute it in the background. It is designed to be launched at start up, but it would not be difficult to modify to run as a daemon or cron task.

### Credit
This project is based on the [Raspberry Pi UPS](http://raspi-ups.appspot.com/en/index.jsp) project by Mathias Kunter.
