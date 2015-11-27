# mbserverd

This is a simple modbus/TCP server for test purpose, write in pure Perl code.

## Setup (for Linux):

    git clone https://github.com/sourceperl/mbserverd.git
    cd mbserverd
    perl Makefile.PL
    make
    sudo make install

## Usage example

### start server

    sudo mbserverd

### stop server

    sudo killall mbserverd

### check server is run

    sudo netstat -ntap

      Connexions Internet actives (serveurs et établies)
      Proto Recv-Q Send-Q Adresse locale          Adresse distante        Etat        PID/Program name
      tcp        0      0 0.0.0.0:502             0.0.0.0:*               LISTEN      3973/perl <- it's modbus server
      tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      2072/sshd

### see inline help

    mbserverd -h

### use with supervisor (to manage start/stop/autorun):

    sudo apt-get install supervisor
    sudo cp etc/supervisor/conf.d/* /etc/supervisor/conf.d/
    sudo supervisorctl update

