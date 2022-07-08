#!/usr/bin/perl -w

use strict;
use warnings;

use Monitoring::Plugin;

my $DEBUG = 0;
############################################################
# check_rittal_rcm.pl
############################################################
# Prototypes
sub ProcessValue($$$);
############################################################
# Startup

my $p = Monitoring::Plugin->new(
  usage => "This plugin checks Rittal RCM devices\n" .
           "Usage: %s [-H <host>] [-C <community>]\n",
  version => 'Version 0.12, July 8 2022, Hajo Kessener'
);

############################################################
# Arguments

$p->add_arg(
  spec => 'host|H=s',
  help => 'hostname or IP address',
  required => 1
);

$p->add_arg(
  spec => 'community|C=s',
  help => 'SNMP community string',
  required => 1
);

$p->getopts();

my $host = $p->opts->host;
my $community = $p->opts->community;

############################################################
# SNMP query

use Net::SNMP;

my $OID = '1.3.6.1.4.1.2606.7.4.2.2.1';

my ($session, $error) = Net::SNMP->session(
   -hostname  => $host,
   -community => $community,
);
 
if (!defined $session) {
   $p->plugin_exit(UNKNOWN,"ERROR: ".$error);
}
 
my $result = $session->get_table(-baseoid => $OID);
 
if (!defined $result) {
   my $error = $session->error();
   $session->close();
   $p->plugin_exit(UNKNOWN,"ERROR: ".$error);
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

# Total.Frequency.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.1');
# Total.Neutral Current.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.3');
# Total.Power.Active.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.12');
# Total.Energy.Active.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.20');
# Total.Energy.Active.Runtime.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.3.2.21');

# Phases L1...L3
for(my $Lx = 1; $Lx <= 3; $Lx++) {

  # OID base:
  my $bx = '1.3.6.1.4.1.2606.7.4.2.2.1.10.2';
  # OID offset:
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.25'
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.60'
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.95'
  my $ox = ($Lx - 1) * 35 + 25;

  # Phase Lx.Voltage.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+ 1)); #26
  # Phase Lx.Voltage.THD.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+ 9)); #34
  # Phase Lx.Current.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+11)); #36
  # Phase Lx.Current.THD.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+19)); #44
  # Phase Lx.Power.Factor.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+20)); #45
  # Phase Lx.Power.Active.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+22)); #47
  # Phase Lx.Power.Reactive.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+30)); #55
  # Phase Lx.Power.Apparent.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+31)); #56
  # Phase Lx.Energy.Active.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+32)); #57
  # Phase Lx.Energy.Apparent.Value
  ProcessValue($p,$result,sprintf("%s.%u",$bx,$ox+34)); #59

  # Phase Lx.Voltage.Status
  my $PhaseVoltageStatus     = $result->{sprintf("%s.%u",$bx,$ox+ 7)}; # 32
  if($PhaseVoltageStatus ne 'OK') {
    $p->add_message(WARNING, qq|L$Lx: $PhaseVoltageStatus|);
  }

  # Phase Lx.Current.Status
  my $PhaseCurrentStatus     = $result->{sprintf("%s.%u",$bx,$ox+17)}; # 42
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

# RCMs.RCM 01.AC.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.137');
# RCMs.RCM 01.AC.SetPtHighAlarm
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.138');
# RCMs.RCM 01.AC.SetPtHighWarn
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.139');

# RCMs.RCM 01.AC.Status
my $RCMsRCM01ACStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.141'};

if($RCMsRCM01ACStatus ne 'OK') {
  $p->add_message(WARNING, qq|RCM01 AC-Status: $RCMsRCM01ACStatus|);
}

# RCMs.RCM 01.DC.Value
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.144');
# RCMs.RCM 01.DC.SetPtHighAlarm
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.145');
# RCMs.RCM 01.DC.SetPtHighWarn
ProcessValue($p,$result,'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.146');

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

$p->plugin_exit(OK, "should add my message!");

############################################################
sub ProcessValue($$$) {
  my($plugin,$result,$baseOID) = @_ or return(undef);

  my($OID,@List);

  # get cmcIIIVarName --> 2606.7.4.2.2.1.3.2.1
  @List = split(/\./,$baseOID); $List[12] = 3; $OID = join('.',@List);
  my $label = $result->{$OID};

  # get cmcIIIVarUnit --> 2606.7.4.2.2.1.5.2.1
  @List = split(/\./,$baseOID); $List[12] = 5; $OID = join('.',@List);
  my $uom = $result->{$OID};

  # get cmcIIIVarType --> 2606.7.4.2.2.1.6.2.1
  @List = split(/\./,$baseOID); $List[12] = 6; $OID = join('.',@List);
  my $type = $result->{$OID};

  # get cmcIIIVarScale --> 2606.7.4.2.2.1.7.2.1
  @List = split(/\./,$baseOID); $List[12] = 7; $OID = join('.',@List);
  my $scale = $result->{$OID};

  # get cmcIIIVarConstraints --> 2606.7.4.2.2.1.8.2.1
  @List = split(/\./,$baseOID); $List[12] = 8; $OID = join('.',@List);
  my $constraints = $result->{$OID};

  # get cmcIIIVarSteps --> 2606.7.4.2.2.1.9.2.1
  @List = split(/\./,$baseOID); $List[12] = 9; $OID = join('.',@List);
  my $steps = $result->{$OID};

  # get cmcIIIVarValueInt --> 2606.7.4.2.2.1.11.2.1
  @List = split(/\./,$baseOID); $List[12] = 11; $OID = join('.',@List);
  my $value = $result->{$OID};

  # do value scaling
  $value = ($scale < 0) ? $value / abs($scale) : $value * $scale;

# my($warn,$crit,$min,$max);

# $warn = 0;
# $crit = 0;
# $min  = 0;
# $max  = 0;

  # label=value[uom];[warn];[crit];[min];[max]
  $plugin->add_perfdata(
    label => $label,
    value => $value,
    uom   => $uom,
#   warn  => $warn,
#   crit  => $crit,
#   min   => $min,
#   max   => $max
  );

  if($DEBUG) {
    print qq|
      ********** ProcessValue **********
      label: $label
      uom: $uom
      type: $type
      scale: $scale
      constraints: $constraints
      steps: $steps
      value: $value
    \n|;
#     warn: $warn
#     crit: $crit
#     min:  $min
#     max:  $max
  }

}

############################################################
1;
