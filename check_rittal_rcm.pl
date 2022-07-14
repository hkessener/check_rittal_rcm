#!/usr/bin/perl -w

use strict;
use warnings;

use Net::SNMP;
use Monitoring::Plugin;

############################################################
# check_rittal_rcm.pl
############################################################
sub ProcessVariable($$$);
sub ProcessVariableWithThresholds($$$);
sub ProcessVariableValue($$);
sub ProcessVariableConstraints($);
sub OID_up($);
############################################################
# Startup

my $p = Monitoring::Plugin->new(
  usage => "This plugin checks Rittal RCM devices\n" .
           "Usage: %s [-H <host>] [-C <community>]\n".
           "or use --help for a list of parameters]\n",
  version => 'Version July 13 2022, Hajo Kessener'
);

############################################################
# Arguments

$p->add_arg(
  spec => 'host|H=s',
  help => 'hostname or IP address',
  required => 1
);

$p->add_arg(
  spec => 'snmp_version|s=s',
  help => 'SNMP version (1|2c|3)',
  default => '2c',
  required => 0
);

$p->add_arg(
  spec => 'community|C=s',
  help => 'SNMP community string',
  required => 0
);

$p->add_arg(
  spec => 'username|u=s',
  help => 'SNMPv3 Username',
  required => 0
);

$p->add_arg(
  spec => 'authpassword',
  help => 'SNMPv3 authPassword',
  required => 0
);

$p->add_arg(
  spec => 'authkey',
  help => 'SNMPv3 authKey',
  required => 0
);

$p->add_arg(
  spec => 'authprotocol',
  help => 'SNMPv3 authProtocol',
  default => 'md5',
  required => 0
);

$p->add_arg(
  spec => 'privpassword',
  help => 'SNMPv3 privPassword',
  required => 0
);

$p->add_arg(
  spec => 'privkey',
  help => 'SNMPv3 privKey',
  required => 0
);

$p->add_arg(
  spec => 'privprotocol',
  help => 'SNMPv3 privProtocol',
  default => 'des',
  required => 0
);

$p->getopts();

############################################################
# SNMP query

my($session,$error);

if($p->opts->snmp_version eq '1' || $p->opts->snmp_version eq '2c') {
  ($session, $error) = Net::SNMP->session(
    -version   => $p->opts->snmp_version,
    -hostname  => $p->opts->host,
    -community => $p->opts->community,
    -timeout   => $p->opts->timeout,
  );
} elsif($p->opts->snmp_version eq '3') {
  if(defined($p->opts->authkey)) {
    ($session, $error) = Net::SNMP->session(
      -version      => $p->opts->snmp_version,
      -hostname     => $p->opts->host,
      -username     => $p->opts->username,
      -authkey      => $p->opts->authkey,
      -authprotocol => $p->opts->authprotocol,
      -timeout      => $p->opts->timeout,
    );
  } elsif(defined($p->opts->authpassword)) {
    ($session, $error) = Net::SNMP->session(
      -version      => $p->opts->snmp_version,
      -hostname     => $p->opts->host,
      -username     => $p->opts->username,
      -authpassword => $p->opts->authpassword,
      -authprotocol => $p->opts->authprotocol,
      -timeout      => $p->opts->timeout,
    );
  } elsif(defined($p->opts->privkey)) {
    ($session, $error) = Net::SNMP->session(
      -version      => $p->opts->snmp_version,
      -hostname     => $p->opts->host,
      -username     => $p->opts->username,
      -privkey      => $p->opts->privkey,
      -privprotocol => $p->opts->privprotocol,
      -timeout      => $p->opts->timeout,
    );
  } elsif(defined($p->opts->privpassword)) {
    ($session, $error) = Net::SNMP->session(
      -version      => $p->opts->snmp_version,
      -hostname     => $p->opts->host,
      -username     => $p->opts->username,
      -privpassword => $p->opts->privpassword,
      -privprotocol => $p->opts->privprotocol,
      -timeout      => $p->opts->timeout,
    );
  } else {
  $error = qq|SNMP credentials incomplete|;
  }
} else {
  $error = qq|SNMP version unknown|;
}
 
unless(defined $session) {
   $p->plugin_exit(UNKNOWN,$error);
}

$session->max_msg_size(8192);
 
my $result = $session->get_table(-baseoid => '1.3.6.1.4.1.2606.7.4.2.2.1');
 
if (!defined $result) {
   my $error = $session->error();
   $session->close();
   $p->plugin_exit(UNKNOWN,$error);
}

############################################################
# Process section "System"

# Input.Status (just informational yet)
my $InputDescName = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.1'};
my $InputStatus   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.5'};

# Output.Status (just informational yet)
my $OutputDescName = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.7'};
my $OutputStatus   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.10'};

# System Health.Temperature
my $SystemHealthTemperatureErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.21'};
my $SystemHealthTemperatureStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.22'};

if($SystemHealthTemperatureStatus ne 'OK') {
  $p->add_message(WARNING, $SystemHealthTemperatureErrorInfo);
}

# System Health.Current
my $SystemHealthCurrentErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.26'};
my $SystemHealthCurrentStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.27'};

if($SystemHealthCurrentStatus ne 'OK') {
  $p->add_message(WARNING, $SystemHealthCurrentErrorInfo);
}

# System Health.Supply
my $SystemHealthSupplyErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.30'};
my $SystemHealthSupplyStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.31'};

if($SystemHealthSupplyStatus ne 'OK') {
  $p->add_message(WARNING, $SystemHealthSupplyErrorInfo);
}

############################################################
# Process section "RCM-Inline"

# Total.Frequency
ProcessVariable($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.1');

# Total.Neutral Current
ProcessVariableWithThresholds($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.3');
my $TotalNeutralCurrentStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.9'};

if($TotalNeutralCurrentStatus ne 'OK') {
  $p->add_message(WARNING, $TotalNeutralCurrentStatus);
}

# Total.Power.Active
my $ok_msg = ProcessVariableWithThresholds($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.12');
my $TotalPowerActiveStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.9'};

if($TotalPowerActiveStatus ne 'OK') {
  $p->add_message(WARNING, $TotalPowerActiveStatus);
}

# Total.Energy.Active
ProcessVariable($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.20');

# Total.Energy.Active.Runtime
ProcessVariable($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.21');

# Phases L1...L3
for(my $Lx = 1; $Lx <= 3; $Lx++) {

  # OID base:
  my $bx = '1.3.6.1.4.1.2606.7.4.2.2.1.10.2';
  # OID offset:
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.25'
  # L2 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.60'
  # L3 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.95'
  my $ox = ($Lx - 1) * 35 + 25;

  # Phase Lx.Voltage
  ProcessVariableWithThresholds($p,$result,sprintf("%s.%u",$bx,$ox+ 1)); #26
  # Phase Lx.Voltage.THD
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+ 9)); #34
  # Phase Lx.Current
  ProcessVariableWithThresholds($p,$result,sprintf("%s.%u",$bx,$ox+11)); #36
  # Phase Lx.Current.THD
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+19)); #44
  # Phase Lx.Power.Factor
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+20)); #45
  # Phase Lx.Power.Active
  ProcessVariableWithThresholds($p,$result,sprintf("%s.%u",$bx,$ox+22)); #47
  # Phase Lx.Power.Reactive
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+30)); #55
  # Phase Lx.Power.Apparent
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+31)); #56
  # Phase Lx.Energy.Active
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+32)); #57
  # Phase Lx.Energy.Apparent
  ProcessVariable($p,$result,sprintf("%s.%u",$bx,$ox+34)); #59

  # Phase Lx.Voltage.Status
  my $PhaseVoltageStatus = $result->{sprintf("%s.%u",$bx,$ox+ 7)}; # 32
  if($PhaseVoltageStatus ne 'OK') {
    $p->add_message(WARNING, qq|L$Lx: $PhaseVoltageStatus|);
  }

  # Phase Lx.Current.Status
  my $PhaseCurrentStatus = $result->{sprintf("%s.%u",$bx,$ox+17)}; # 42
  if($PhaseCurrentStatus ne 'OK') {
    $p->add_message(WARNING, qq|L$Lx: $PhaseCurrentStatus|);
  }

  # Phase Lx.Power.Active.Status
  my $PhasePowerActiveStatus = $result->{sprintf("%s.%u",$bx,$ox+28)}; # 53
  if($PhasePowerActiveStatus ne 'OK') {
    $p->add_message(WARNING, qq|L$Lx: $PhasePowerActiveStatus|);
  }
}

############################################################
# Process section "RCM 01"

# RCMs.RCM 01.General.Status
my $RCMsRCM01GeneralStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.134'};
if($RCMsRCM01GeneralStatus ne 'OK') {
  $p->add_message(WARNING, qq|RCM01 General-Status: $RCMsRCM01GeneralStatus|);
}

# RCMs.RCM 01.AC
ProcessVariable($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.137');
# RCMs.RCM 01.AC.Status
my $RCMsRCM01ACStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.141'};

if($RCMsRCM01ACStatus ne 'OK') {
  $p->add_message(WARNING, qq|RCM01 AC-Status: $RCMsRCM01ACStatus|);
}

# RCMs.RCM 01.DC
ProcessVariable($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.144');
# RCMs.RCM 01.DC.Status
my $RCMsRCM01DCStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.148'};

if($RCMsRCM01DCStatus ne 'OK') {
  $p->add_message(WARNING, qq|RCM01 DC-Status: $RCMsRCM01DCStatus|);
}

###########################################################
# SNMP query done
$session->close();

###########################################################
# output results

my($code,$msgs) = $p->check_messages();

if($code != OK) {
  $p->plugin_exit($code,$msgs);
}

$p->plugin_exit(OK, $ok_msg);

############################################################
sub ProcessVariable($$$) {
  my($plugin,$result,$subOID) = @_ or return(undef);

  # the variable itself
  my($label,$uom,$value,$min,$max) = ProcessVariableValue($result,$subOID);

  # put all this together into a perfdata item
  # label=value[uom];;;[min];[max]
  $plugin->add_perfdata(
    label => $label,
    value => $value,
    uom   => $uom,
    min   => $min,
    max   => $max
  );

  return(qq|$label is $value $uom|);
}
############################################################
sub ProcessVariableWithThresholds($$$) {
  my($plugin,$result,$subOID) = @_ or return(undef);

  # the variable itself
  my($label,$uom,$value,$min,$max) = ProcessVariableValue($result,$subOID);

  # critical high
  $subOID = OID_up($subOID);
  my($ch_label,$ch_uom,$ch_value,$ch_min,$ch_max) = ProcessVariableValue($result,$subOID);

  # warning high
  $subOID = OID_up($subOID);
  my($wh_label,$wh_uom,$wh_value,$wh_min,$wh_max) = ProcessVariableValue($result,$subOID);

  # warning low
  $subOID = OID_up($subOID);
  my($wl_label,$wl_uom,$wl_value,$wl_min,$wl_max) = ProcessVariableValue($result,$subOID);

  # critical low
  $subOID = OID_up($subOID);
  my($cl_label,$cl_uom,$cl_value,$cl_min,$cl_max) = ProcessVariableValue($result,$subOID);

  my $warn = "$wl_value:$wh_value";
  my $crit = "$cl_value:$ch_value";

  # put all this together into a perfdata item
  # label=value[uom];[warn];[crit];[min];[max]
  $plugin->add_perfdata(
    label => $label,
    value => $value,
    uom   => $uom,
    warn  => $warn,
    crit  => $crit,
    min   => $min,
    max   => $max
  );

  return(qq|$label is $value $uom|);
}
############################################################
sub ProcessVariableValue($$) {
  my($result,$subOID) = @_ or return(undef);

  my($oid,@list);

  # get cmcIIIVarName
  @list = split(/\./,$subOID); $list[12] = 3; $oid = join('.',@list);
  my $label = $result->{$oid};

  # get cmcIIIVarUnit
  @list = split(/\./,$subOID); $list[12] = 5; $oid = join('.',@list);
  my $uom = $result->{$oid};

  # get cmcIIIVarScale
  @list = split(/\./,$subOID); $list[12] = 7; $oid = join('.',@list);
  my $scale = $result->{$oid};

  # get cmcIIIVarConstraints
  @list = split(/\./,$subOID); $list[12] = 8; $oid = join('.',@list);
  my $constraints = $result->{$oid};

  # get cmcIIIVarValueInt
  @list = split(/\./,$subOID); $list[12] = 11; $oid = join('.',@list);
  my $value = $result->{$oid};

  # do value scaling
  $value = ($scale < 0) ? $value / abs($scale) : $value * $scale;

  # get constraints
  my($min,$max) = ProcessVariableConstraints($constraints);

  return($label,$uom,$value,$min,$max);
}
############################################################
sub ProcessVariableConstraints($) {
  my $string = shift(@_) or return(undef);

  # the string presented by RCM looks like this:
  # "integer: min 0, max 2000000000, scale /10, step 1"
  #
  # for now, we want to extract 'min' and 'max' values

  my $min = '';
  my $max = '';

  # first remove ':' and ','
  $string =~ s/:|,//g;

  # split remaining items into list
  my @items = split(/ /,$string);

  # extract min and max values
  for(my $i = 0; $i < @items; $i++) {
    $min = $items[$i+1] if($items[$i] eq 'min');
    $max = $items[$i+1] if($items[$i] eq 'max');
  }

  return($min,$max);
}
############################################################
sub OID_up($) {
  my($oid) = shift(@_) or return(undef);

  my @list = split('\.',$oid);
  my $ix = pop(@list); $ix++; push(@list,$ix);

  $oid = join('.',@list);

  return($oid);
}
############################################################
1;
