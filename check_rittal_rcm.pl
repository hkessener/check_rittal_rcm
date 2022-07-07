#!/usr/bin/perl -w

use strict;
use warnings;

use Monitoring::Plugin;

my $DEBUG = 0;
############################################################
# check_rittal_rcm.pl
############################################################

my $p = Monitoring::Plugin->new(
  usage => "This plugin checks Rittal RCM devices\n" .
           "Usage: %s [-H <host>] [-C <community>]\n",
  version => 'Version 0.11, July 7 2022, Hajo Kessener'
);

############################################################

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

my(@PData,@EMesg);

# ---------------- System ----------------

my $InputDescName   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.1'};
my $InputStatus     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.5'};
$DEBUG and print qq|$InputDescName: $InputStatus\n|;

my $OutputDescName  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.7'};
my $OutputStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.10'};
$DEBUG and print qq|$OutputDescName: $OutputStatus\n|;

my $SystemHealthTemperatureErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.21'};
my $SystemHealthTemperatureStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.22'};
$DEBUG and print qq|System-Health Temperature: $SystemHealthTemperatureStatus ($SystemHealthTemperatureErrorInfo)\n|;

if($SystemHealthTemperatureStatus ne 'OK') {
  push(@EMesg, $SystemHealthTemperatureErrorInfo);
}

my $SystemHealthCurrentErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.26'};
my $SystemHealthCurrentStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.27'};
$DEBUG and print qq|System-Health Current: $SystemHealthCurrentStatus ($SystemHealthCurrentErrorInfo)\n|;

if($SystemHealthCurrentStatus ne 'OK') {
  push(@EMesg, $SystemHealthCurrentErrorInfo);
}

my $SystemHealthSuppyErrorInfo = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.30'};
my $SystemHealthSuppyStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.1.31'};
$DEBUG and print qq|System-Health Supply: $SystemHealthSuppyStatus ($SystemHealthSuppyErrorInfo)\n|;

if($SystemHealthSuppyStatus ne 'OK') {
  push(@EMesg, $SystemHealthSuppyErrorInfo);
}

# ---------------- RCM-Inline ----------------

my $TotalFrequencyValue = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.1'};
$DEBUG and print qq|Mains Frequency: $TotalFrequencyValue\n|;
$TotalFrequencyValue =~ s/ //g;
push(@PData, qq|'Total Frequency'=$TotalFrequencyValue|);

my $TotalNeutralCurrentDescName  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.2'};
my $TotalNeutralCurrentStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.3'};
$DEBUG and print qq|$TotalNeutralCurrentDescName: $TotalNeutralCurrentStatus\n|;
$TotalNeutralCurrentStatus =~ s/ //g;
push(@PData, qq|'Total Neutral Current'=$TotalNeutralCurrentStatus|);

my $TotalPowerActiveDescName  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.11'};
my $TotalPowerActiveStatus    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.12'};
$DEBUG and print qq|$TotalPowerActiveDescName: $TotalPowerActiveStatus\n|;
$TotalPowerActiveStatus =~ s/ //g;
push(@PData, qq|'Total Power Active'=$TotalPowerActiveStatus|);

my $TotalEnergyActiveValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.20'};
my $TotalEnergyActiveRuntimeValue = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.21'};
$DEBUG and print qq|Total Energy Active: $TotalEnergyActiveValue ($TotalEnergyActiveRuntimeValue)\n|;
$TotalEnergyActiveValue =~ s/ //g;
push(@PData, qq|'Total Energy Active'=$TotalEnergyActiveValue|);
$TotalEnergyActiveRuntimeValue =~ s/ //g;
push(@PData, qq|'Total Energy Active Runtime'=$TotalEnergyActiveRuntimeValue|);

# Phases L1...L3
for(my $Lx = 1; $Lx <= 3; $Lx++) {

  # OID base:
  my $bx = '1.3.6.1.4.1.2606.7.4.2.2.1.10.2';
  # OID offset:
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.25'
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.60'
  # L1 values start at OID '1.3.6.1.4.1.2606.7.4.2.2.1.10.2.95'
  my $ox = ($Lx - 1) * 35 + 25;

  my $PhaseVoltageDescName     = $result->{sprintf("%s.%u",$bx,$ox+ 0)}; # 25
  my $PhaseVoltageValue        = $result->{sprintf("%s.%u",$bx,$ox+ 1)}; # 26
  my $PhaseVoltageStatus       = $result->{sprintf("%s.%u",$bx,$ox+ 7)}; # 32
  my $PhaseVoltageTHDValue     = $result->{sprintf("%s.%u",$bx,$ox+ 9)}; # 34
  my $PhaseCurrentDescName     = $result->{sprintf("%s.%u",$bx,$ox+10)}; # 35
  my $PhaseCurrentValue        = $result->{sprintf("%s.%u",$bx,$ox+11)}; # 36
  my $PhaseCurrentStatus       = $result->{sprintf("%s.%u",$bx,$ox+17)}; # 42
  my $PhaseCurrentTHDValue     = $result->{sprintf("%s.%u",$bx,$ox+19)}; # 44
  my $PhasePowerFactorValue    = $result->{sprintf("%s.%u",$bx,$ox+20)}; # 45
  my $PhasePowerActiveDescName = $result->{sprintf("%s.%u",$bx,$ox+21)}; # 46
  my $PhasePowerActiveValue    = $result->{sprintf("%s.%u",$bx,$ox+22)}; # 47
  my $PhasePowerActiveStatus   = $result->{sprintf("%s.%u",$bx,$ox+28)}; # 53
  my $PhasePowerReactiveValue  = $result->{sprintf("%s.%u",$bx,$ox+30)}; # 55
  my $PhasePowerApparentValue  = $result->{sprintf("%s.%u",$bx,$ox+31)}; # 56
  my $PhaseEnergyActiveValue   = $result->{sprintf("%s.%u",$bx,$ox+32)}; # 57
  my $PhaseEnergyApparentValue = $result->{sprintf("%s.%u",$bx,$ox+34)}; # 59
  $DEBUG and print qq|$PhaseVoltageDescName: $PhaseVoltageValue ($PhaseVoltageStatus)\n|;
  $DEBUG and print qq|Phase L$Lx VoltageTHDValue: $PhaseVoltageTHDValue\n|;
  $DEBUG and print qq|$PhaseCurrentDescName: $PhaseCurrentValue ($PhaseCurrentStatus)\n|;
  $DEBUG and print qq|Phase L$Lx CurrentTHDValue: $PhaseCurrentTHDValue\n|;
  $DEBUG and print qq|Phase L$Lx PowerFactorValue: $PhasePowerFactorValue\n|;
  $DEBUG and print qq|$PhasePowerActiveDescName: $PhasePowerActiveValue ($PhasePowerActiveStatus)\n|;
  $DEBUG and print qq|Phase L$Lx PowerReactiveValue: $PhasePowerReactiveValue\n|;
  $DEBUG and print qq|Phase L$Lx PowerApparentValue: $PhasePowerApparentValue\n|;
  $DEBUG and print qq|Phase L$Lx EnergyActiveValue: $PhaseEnergyActiveValue\n|;
  $DEBUG and print qq|Phase L$Lx EnergyApparentValue: $PhaseEnergyApparentValue\n|;

  if($PhaseVoltageStatus ne 'OK') {
    push(@EMesg, qq|L$Lx: $PhaseVoltageStatus|);
  }
  if($PhaseCurrentStatus ne 'OK') {
    push(@EMesg, qq|L$Lx: $PhaseCurrentStatus|);
  }
  if($PhasePowerActiveStatus ne 'OK') {
    push(@EMesg, qq|L$Lx: $PhasePowerActiveStatus|);
  }
  $PhaseVoltageValue =~ s/ //g;
  push(@PData, qq|'L$Lx Voltage'=$PhaseVoltageValue|);
  $PhaseVoltageTHDValue =~ s/ //g;
  push(@PData, qq|'L$Lx Voltage THD'=$PhaseVoltageTHDValue|);
  $PhaseCurrentValue =~ s/ //g;
  push(@PData, qq|'L$Lx Current'=$PhaseCurrentValue|);
  $PhaseCurrentTHDValue =~ s/ //g;
  push(@PData, qq|'L$Lx Current THD'=$PhaseCurrentTHDValue|);
  push(@PData, qq|'L$Lx Power Factor'=$PhasePowerFactorValue|);
  $PhasePowerActiveValue =~ s/ //g;
  push(@PData, qq|'L$Lx Power Active'=$PhasePowerActiveValue|);
  $PhasePowerReactiveValue =~ s/ //g;
  push(@PData, qq|'L$Lx Power Reactive'=$PhasePowerReactiveValue|);
  $PhasePowerApparentValue =~ s/ //g;
  push(@PData, qq|'L$Lx Power Apparent'=$PhasePowerApparentValue|);
  $PhaseEnergyActiveValue =~ s/ //g;
  push(@PData, qq|'L$Lx Energy Active'=$PhaseEnergyActiveValue|);
  $PhaseEnergyApparentValue =~ s/ //g;
  push(@PData, qq|'L$Lx Energy Apparent'=$PhaseEnergyApparentValue|);
}

# RCM01
my $RCMsRCM01GeneralStatus = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.134'};
$DEBUG and print qq|RCMsRCM01GeneralStatus: $RCMsRCM01GeneralStatus\n|;
if($RCMsRCM01GeneralStatus ne 'OK') {
  push(@EMesg, qq|RCM01 General-Status: $RCMsRCM01GeneralStatus|);
}

my $RCMsRCM01ACDescName       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.136'};
my $RCMsRCM01ACValue          = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.137'};
my $RCMsRCM01ACSetPtHighAlarm = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.138'};
my $RCMsRCM01ACSetPtHighWarn  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.139'};
my $RCMsRCM01ACStatus         = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.141'};
$DEBUG and print qq|$RCMsRCM01ACDescName: $RCMsRCM01ACValue;[$RCMsRCM01ACSetPtHighWarn];[$RCMsRCM01ACSetPtHighAlarm] ($RCMsRCM01ACStatus)\n|;
if($RCMsRCM01ACStatus ne 'OK') {
  push(@EMesg, qq|RCM01 AC-Status: $RCMsRCM01ACStatus|);
}
$RCMsRCM01ACValue =~ s/ //g;
push(@PData, qq|'RCM AC value'=$RCMsRCM01ACValue|);
$RCMsRCM01ACSetPtHighAlarm =~ s/ //g;
push(@PData, qq|'RCM AC Setpoint High Alarm'=$RCMsRCM01ACSetPtHighAlarm|);
$RCMsRCM01ACSetPtHighWarn =~ s/ //g;
push(@PData, qq|'RCM AC Setpoint High Warn'=$RCMsRCM01ACSetPtHighWarn|);

my $RCMsRCM01DCDescName       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.143'};
my $RCMsRCM01DCValue          = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.144'};
my $RCMsRCM01DCSetPtHighAlarm = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.145'};
my $RCMsRCM01DCSetPtHighWarn  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.146'};
my $RCMsRCM01DCStatus         = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.148'};
$DEBUG and print qq|$RCMsRCM01DCDescName: $RCMsRCM01DCValue;[$RCMsRCM01DCSetPtHighWarn];[$RCMsRCM01DCSetPtHighAlarm] ($RCMsRCM01DCStatus)\n|;
if($RCMsRCM01DCStatus ne 'OK') {
  push(@EMesg, qq|RCM01 DC-Status: $RCMsRCM01DCStatus|);
}
$RCMsRCM01DCValue =~ s/ //g;
push(@PData, qq|'RCM DC value'=$RCMsRCM01DCValue|);
$RCMsRCM01DCSetPtHighAlarm =~ s/ //g;
push(@PData, qq|'RCM DC Setpoint High Alarm'=$RCMsRCM01DCSetPtHighAlarm|);
$RCMsRCM01DCSetPtHighWarn =~ s/ //g;
push(@PData, qq|'RCM DC Setpoint High Warn'=$RCMsRCM01DCSetPtHighWarn|);

# done
$session->close();

############################################################
# output results

#$p->add_perfdata(... to be done...);
my $pdata_output = join(' ', @PData);

if(@EMesg > 0) {
  my $msg = join('. ',@EMesg);
     $msg .= ' | '. $pdata_output;
  $p->plugin_exit(WARNING, $msg);
} else {
  my $msg = qq|Total Power Active is $TotalPowerActiveStatus|;
     $msg .= ' | '. $pdata_output;
  $p->plugin_exit(OK, $msg);
}

############################################################
1;
