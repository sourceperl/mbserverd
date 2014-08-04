# mbserverd

This is a simple modbus/TCP server for test purpose, write in pure Perl code.

## Setup (for Linux):
1. just copy mbserverd to /usr/local/bin/ (it's the script path for user scripts in debian system).
2. set chmod +x /usr/local/bin/mbserverd to set execution flag.

## Usage example

### start server

    pi@raspberrypi ~ $ sudo mbserverd

### stop server
    
    pi@raspberrypi ~ $ sudo killall mbserverd

### check server is run

    pi@raspberrypi ~ $ sudo netstat -ntap
    Connexions Internet actives (serveurs et établies)
    Proto Recv-Q Send-Q Adresse locale          Adresse distante        Etat        PID/Program name
    tcp        0      0 0.0.0.0:502             0.0.0.0:*               LISTEN      3973/perl <- it's modbus server
    tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      2072/sshd

## License

Software under version 3 of the GNU General Public License (http://www.gnu.org/licenses/quick-guide-gplv3.en.html).
