#!/usr/bin/perl -w

# Server Modbus/TCP multi-client
#     Version: 1.3.0
#     Website: http://source.perl.free.fr
#        Date: 10/03/2013
#     License: GPL v3 (http://www.gnu.org/licenses/quick-guide-gplv3.en.html)
# Description: Server Modbus/TCP multi-threaded 
#              function build-in: 3, 4, 6 and 16
#       Notes: - The script uses the share memory mechanism provides by IPC System V for data
#              exchange between each process (a process by process TCP link + 1 father)
#              (sys V french doc : http://jean-luc.massat.perso.luminy.univmed.fr/ens/docs/IPC.html)
#              - Open TCP port 502 in listening mode requires privileged "root"

### changelog
# 1.3.0: code and comment is now in english (more easy to share)
# 1.1.0: Change header for source code release
### todo
# - add arg to the command line call (for modified TCP port ...)

use strict;
use Sys::Syslog;
use POSIX;
use Socket;
use IPC::SysV qw(IPC_RMID IPC_PRIVATE); # share mem !!! OS Unix only

# must be start by root
if ($> != 0) {
  printf STDERR	"modbus server must be run by root\n";
  log_mesg('modbus server must be run by root, exit');
  exit 1;
}

# some names
my $syslog_name = 'mbserverd';
my $pidfile     = '/var/run/mbserverd.pid';

# share memory info
my $shm_flags   = 0666;     # shm flag rw-rw-rw-
my $shm_size    = 65536*2;  # size of share mem
# allocate share mem
my $sid = shmget(IPC_PRIVATE, $shm_size, $shm_flags);

# ModBus/TCP value
my $modbus_port              = 502;   # ModBus default port
# protocol ID (field of modbus/TCP header)
my $MODBUS_PROTOCOL_ID       = 0;
# functions codes
my $READ_HOLDING_REGISTERS   = 0x03;
my $READ_INPUT_REGISTERS     = 0x04;
my $WRITE_SINGLE_REGISTER    = 0x06;
my $WRITE_MULTIPLE_REGISTERS = 0x10;
# excepts codes
my $EXP_NO_EXCEPTION         = 0x00;
my $EXP_ILLEGAL_FUNCTION     = 0x01;
my $EXP_DATA_ADDRESS         = 0x02;
my $EXP_DATA_VALUE           = 0x03;
# constant
my $IPPROTO_TCP              = 0x06;
my $TCP_NODELAY              = 0x01;

# startup message
log_mesg("modbus server started");

# daemonize (call exit for process father)
exit 0 if  !(fork == 0);
# current process is process group leader (main daemon)
setpgrp(0, 0);

# create PID file
open (PID, ">$pidfile");
print PID "$$\n";
close PID;

# signals setup
$SIG{TERM} = sub {
  if (getppid() == 1) {
    # for the father process...
    # del PID file and shm memory
    unlink $pidfile;
    # free share memory
    shmctl ($sid, IPC_RMID, 0); 
    # restore default CHLD handler
    $SIG{CHLD} = 'DEFAULT';
    # kill childs process (on same process group)
    local $SIG{TERM} = 'IGNORE'; # avoid deep recursion
    kill 'TERM', -$$;
    # wait end of every childs
    while (wait != -1) {}
    # close socket
    close Server;
  } else {
    # for child process...
    # close socket
    exit 0;
  }
};

# for remove child zombie process
$SIG{CHLD} = 'IGNORE';

# setup protocol
my $proto = getprotobyname('tcp');

# open modbus/TCP port in listen mode
socket(Server, PF_INET, SOCK_STREAM, $proto);
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsockopt error $!\n";
setsockopt(Server, SOL_SOCKET, SO_KEEPALIVE, 1) or die "setsockopt error $!\n";
setsockopt(Server, $IPPROTO_TCP, $TCP_NODELAY, 1) or die "setsockopt error $!\n";
bind (Server, sockaddr_in($modbus_port, INADDR_ANY)) or die "bind port error $modbus_port\n";
listen (Server, SOMAXCONN) or die "listen: $!";
my $paddr;
# connection loop
CLIENT_ACCEPT:
while($paddr = accept(Client, Server)) {
  # make a fork for every new connection
  my $pid_fils;
  if ($pid_fils = fork) {
    # father close handle and go wait next connection
    close Client;
    next CLIENT_ACCEPT;
  }
  defined($pid_fils) or die "unable to fork : $!";
  # child close unused handle
  close Server;
  my ($client_port, $client_addr) = sockaddr_in($paddr);
  my ($head_tr_id, $head_pr_id, $head_length);
  my ($unit_id, $mb_fc, $bc, $ref, $count, $data, @data, $line, $header, $sent, $frame, $value);
  # client msg loop
  while(1) {
    # read 7 bytes header (transaction identifier, protocol identifier, length, unit id)
    recv Client, $line, 7, MSG_WAITALL;
    # if TCP link is close
    if (length($line) != 7) {
      # free socket and end of child process
      close Client;
      exit;
    }
    ($head_tr_id, $head_pr_id, $head_length, $unit_id) = unpack "nnnC", $line;
    # check header
    if ($head_pr_id != $MODBUS_PROTOCOL_ID) {
      # free socket and end of child process
      close Client;
      exit;
    }
    # read frame body
    recv Client, $line, $head_length-1, MSG_WAITALL;
    # if TCP link is close
    if (length($line) == 0) {
      # free socket and end of child process
      close Client;
      exit;
    }
    # decode function code and unit id
    ($mb_fc, $line) = unpack "Ca*", $line;
    # init except var
    my $exp_status = $EXP_NO_EXCEPTION;
    # for every function code
    if ( ($mb_fc == $READ_HOLDING_REGISTERS) || ($mb_fc == $READ_INPUT_REGISTERS) ) {
      # read some words
      ($ref, $count) = unpack "nn", $line;
      if (($count <= 127) && (shmread $sid, $line, 2*$ref, 2*$count)) {
        $line = pack('n*', unpack 'S*', $line);
        $header = pack 'nnnCCC', $head_tr_id, $head_pr_id, 2*$count+3, $unit_id, $mb_fc, 2*$count;
        $frame = $header . $line;
      } else {
        $exp_status = $EXP_DATA_ADDRESS;
      }
    } elsif ( $mb_fc == $WRITE_SINGLE_REGISTER ) {
      # write a word
      ($ref, $value) = unpack "nn", $line;
      if (shmwrite ($sid, pack ('S', $value), 2*$ref, 2)) {
        $frame = pack 'nnnCCnn', $head_tr_id, $head_pr_id, 6, $unit_id, $mb_fc, $ref, $value;
      } else {
        $exp_status = $EXP_DATA_ADDRESS;
      }
    } elsif ( $mb_fc == $WRITE_MULTIPLE_REGISTERS ) {
      # write words
      ($ref, $count, $bc, @data) = unpack 'nnCn*', $line;
      if (shmwrite ($sid, pack ('S*', @data), 2*$ref, 2*$count)) {
        $frame = pack 'nnnCCnn', $head_tr_id, $head_pr_id, 6, $unit_id, $mb_fc, $ref, $count;
      } else {
        $exp_status = $EXP_DATA_ADDRESS;
      }
    } else {
      # for unknown function code
      $exp_status = $EXP_ILLEGAL_FUNCTION;
    }
    # if except : build except frame
    if ($exp_status != $EXP_NO_EXCEPTION) {
      $frame = pack 'nnnCCC', $head_tr_id, $head_pr_id, 3, $unit_id, $mb_fc + 0x80, $exp_status;
    }
    # send answer
    send(Client, $frame, 0);
  } # end of msg loop
} # end of connect loop
# *** add for $SIG{CHLD} bug ***
#goto CLIENT_ACCEPT;
# ********************************************

# *** misc sub ***

# log_mesg(mesg) write mesg on syslog
sub log_mesg {
  my ($mesg) = @_;
  openlog($syslog_name, 'ndelay', 'daemon');
  syslog('notice', $mesg);
  closelog();
}
