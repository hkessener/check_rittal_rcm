#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;

my $DEBUG = 0;
############################################################
# check_rittal_rcm.pl
# 04.07.2022, H. Kessener, LUIS
############################################################
sub printHelp() {
  print qq|
This plugin checks Rittal RCM devices.

Usage: $0 -H <host> -C <community>

|;
}
############################################################
# nagios exit codes

use constant EXIT_OK       => 0;
use constant EXIT_WARNING  => 1;
use constant EXIT_CRITICAL => 2;
use constant EXIT_UNKNOWN  => 3;
############################################################

Getopt::Long::Configure("bundling");

my($opt_V,$opt_h,$opt_H,$opt_C,$opt_I,$opt_w,$opt_c);

GetOptions(
  "V"   => \$opt_V, "version"     => \$opt_V,
  "h"   => \$opt_h, "help"        => \$opt_h,
  "H=s" => \$opt_H, "hostname=s"  => \$opt_H,
  "C=s" => \$opt_C, "community=s" => \$opt_C,
);

if($opt_V||$opt_h) {
  printHelp();
  exit(EXIT_UNKNOWN);
}

my($host,$community);

unless($opt_H) {
  printHelp();
  exit(EXIT_UNKNOWN);
} else {
  $host = $opt_H;
}

if($opt_C) {
  $community = $opt_C;
}

############################################################

use Net::SNMP;

my $OID = '1.3.6.1.4.1.2606.7.4.2.2.1';

my ($session, $error) = Net::SNMP->session(
   -hostname  => $host      || 'localhost',
   -community => $community || 'public',
);
 
if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit EXIT_UNKNOWN;
}
 
my $result = $session->get_table(-baseoid => $OID);
 
if (!defined $result) {
   printf "ERROR: %s.\n", $session->error();
   $session->close();
   exit EXIT_UNKNOWN;
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

# Phase 1
my $PhaseL1VoltageDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.25'};
my $PhaseL1VoltageValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.26'};
my $PhaseL1VoltageStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.32'};
my $PhaseL1VoltageTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.34'};
my $PhaseL1CurrentDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.35'};
my $PhaseL1CurrentValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.36'};
my $PhaseL1CurrentStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.42'};
my $PhaseL1CurrentTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.44'};
my $PhaseL1PowerFactorValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.45'};
my $PhaseL1PowerActiveDescName = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.46'};
my $PhaseL1PowerActiveValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.47'};
my $PhaseL1PowerActiveStatus   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.53'};
my $PhaseL1PowerReactiveValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.55'};
my $PhaseL1PowerApparentValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.56'};
my $PhaseL1EnergyActiveValue   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.57'};
my $PhaseL1EnergyApparentValue = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.59'};
$DEBUG and print qq|$PhaseL1VoltageDescName: $PhaseL1VoltageValue ($PhaseL1VoltageStatus)\n|;
$DEBUG and print qq|PhaseL1VoltageTHDValue: $PhaseL1VoltageTHDValue\n|;
$DEBUG and print qq|$PhaseL1CurrentDescName: $PhaseL1CurrentValue ($PhaseL1CurrentStatus)\n|;
$DEBUG and print qq|PhaseL1CurrentTHDValue: $PhaseL1CurrentTHDValue\n|;
$DEBUG and print qq|PhaseL1PowerFactorValue: $PhaseL1PowerFactorValue\n|;
$DEBUG and print qq|$PhaseL1PowerActiveDescName: $PhaseL1PowerActiveValue ($PhaseL1PowerActiveStatus)\n|;
$DEBUG and print qq|PhaseL1PowerReactiveValue: $PhaseL1PowerReactiveValue\n|;
$DEBUG and print qq|PhaseL1PowerApparentValue: $PhaseL1PowerApparentValue\n|;
$DEBUG and print qq|PhaseL1EnergyActiveValue: $PhaseL1EnergyActiveValue\n|;
$DEBUG and print qq|PhaseL1EnergyApparentValue: $PhaseL1EnergyApparentValue\n|;

if($PhaseL1VoltageStatus ne 'OK') {
  push(@EMesg, qq|L1: $PhaseL1VoltageStatus|);
}
if($PhaseL1CurrentStatus ne 'OK') {
  push(@EMesg, qq|L1: $PhaseL1CurrentStatus|);
}
if($PhaseL1PowerActiveStatus ne 'OK') {
  push(@EMesg, qq|L1: $PhaseL1PowerActiveStatus|);
}
$PhaseL1VoltageValue =~ s/ //g;
push(@PData, qq|'L1 Voltage'=$PhaseL1VoltageValue|);
$PhaseL1VoltageTHDValue =~ s/ //g;
push(@PData, qq|'L1 Voltage THD'=$PhaseL1VoltageTHDValue|);
$PhaseL1CurrentValue =~ s/ //g;
push(@PData, qq|'L1 Current'=$PhaseL1CurrentValue|);
$PhaseL1CurrentTHDValue =~ s/ //g;
push(@PData, qq|'L1 Current THD'=$PhaseL1CurrentTHDValue|);
push(@PData, qq|'L1 Power Factor'=$PhaseL1PowerFactorValue|);
$PhaseL1PowerActiveValue =~ s/ //g;
push(@PData, qq|'L1 Power Active'=$PhaseL1PowerActiveValue|);
$PhaseL1PowerReactiveValue =~ s/ //g;
push(@PData, qq|'L1 Power Reactive'=$PhaseL1PowerReactiveValue|);
$PhaseL1PowerApparentValue =~ s/ //g;
push(@PData, qq|'L1 Power Apparent'=$PhaseL1PowerApparentValue|);
$PhaseL1EnergyActiveValue =~ s/ //g;
push(@PData, qq|'L1 Energy Active'=$PhaseL1EnergyActiveValue|);
$PhaseL1EnergyApparentValue =~ s/ //g;
push(@PData, qq|'L1 Energy Apparent'=$PhaseL1EnergyApparentValue|);

# Phase 2
my $PhaseL2VoltageDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.60'};
my $PhaseL2VoltageValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.61'};
my $PhaseL2VoltageStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.67'};
my $PhaseL2VoltageTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.69'};
my $PhaseL2CurrentDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.70'};
my $PhaseL2CurrentValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.71'};
my $PhaseL2CurrentStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.77'};
my $PhaseL2CurrentTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.79'};
my $PhaseL2PowerFactorValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.80'};
my $PhaseL2PowerActiveDescName = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.81'};
my $PhaseL2PowerActiveValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.82'};
my $PhaseL2PowerActiveStatus   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.88'};
my $PhaseL2PowerReactiveValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.90'};
my $PhaseL2PowerApparentValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.91'};
my $PhaseL2EnergyActiveValue   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.92'};
my $PhaseL2EnergyApparentValue = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.94'};
$DEBUG and print qq|$PhaseL2VoltageDescName: $PhaseL2VoltageValue ($PhaseL2VoltageStatus)\n|;
$DEBUG and print qq|PhaseL2VoltageTHDValue: $PhaseL2VoltageTHDValue\n|;
$DEBUG and print qq|$PhaseL2CurrentDescName: $PhaseL2CurrentValue ($PhaseL2CurrentStatus)\n|;
$DEBUG and print qq|PhaseL2CurrentTHDValue: $PhaseL2CurrentTHDValue\n|;
$DEBUG and print qq|PhaseL2PowerFactorValue: $PhaseL2PowerFactorValue\n|;
$DEBUG and print qq|$PhaseL2PowerActiveDescName: $PhaseL2PowerActiveValue ($PhaseL2PowerActiveStatus)\n|;
$DEBUG and print qq|PhaseL2PowerReactiveValue: $PhaseL2PowerReactiveValue\n|;
$DEBUG and print qq|PhaseL2PowerApparentValue: $PhaseL2PowerApparentValue\n|;
$DEBUG and print qq|PhaseL2EnergyActiveValue: $PhaseL2EnergyActiveValue\n|;
$DEBUG and print qq|PhaseL2EnergyApparentValue: $PhaseL2EnergyApparentValue\n|;

if($PhaseL2VoltageStatus ne 'OK') {
  push(@EMesg, qq|L2: $PhaseL2VoltageStatus|);
}
if($PhaseL2CurrentStatus ne 'OK') {
  push(@EMesg, qq|L2: $PhaseL2CurrentStatus|);
}
if($PhaseL2PowerActiveStatus ne 'OK') {
  push(@EMesg, qq|L2: $PhaseL2PowerActiveStatus|);
}
$PhaseL2VoltageValue =~ s/ //g;
push(@PData, qq|'L2 Voltage'=$PhaseL2VoltageValue|);
$PhaseL2VoltageTHDValue =~ s/ //g;
push(@PData, qq|'L2 Voltage THD'=$PhaseL2VoltageTHDValue|);
$PhaseL2CurrentValue =~ s/ //g;
push(@PData, qq|'L2 Current'=$PhaseL2CurrentValue|);
$PhaseL2CurrentTHDValue =~ s/ //g;
push(@PData, qq|'L2 Current THD'=$PhaseL2CurrentTHDValue|);
push(@PData, qq|'L2 Power Factor'=$PhaseL2PowerFactorValue|);
$PhaseL2PowerActiveValue =~ s/ //g;
push(@PData, qq|'L2 Power Active'=$PhaseL2PowerActiveValue|);
$PhaseL2PowerReactiveValue =~ s/ //g;
push(@PData, qq|'L2 Power Reactive'=$PhaseL2PowerReactiveValue|);
$PhaseL2PowerApparentValue =~ s/ //g;
push(@PData, qq|'L2 Power Apparent'=$PhaseL2PowerApparentValue|);
$PhaseL2EnergyActiveValue =~ s/ //g;
push(@PData, qq|'L2 Energy Active'=$PhaseL2EnergyActiveValue|);
$PhaseL2EnergyApparentValue =~ s/ //g;
push(@PData, qq|'L2 Energy Apparent'=$PhaseL2EnergyApparentValue|);

# Phase 3
my $PhaseL3VoltageDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.95'};
my $PhaseL3VoltageValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.96'};
my $PhaseL3VoltageStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.102'};
my $PhaseL3VoltageTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.104'};
my $PhaseL3CurrentDescName     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.105'};
my $PhaseL3CurrentValue        = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.106'};
my $PhaseL3CurrentStatus       = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.112'};
my $PhaseL3CurrentTHDValue     = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.114'};
my $PhaseL3PowerFactorValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.115'};
my $PhaseL3PowerActiveDescName = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.116'};
my $PhaseL3PowerActiveValue    = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.117'};
my $PhaseL3PowerActiveStatus   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.123'};
my $PhaseL3PowerReactiveValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.125'};
my $PhaseL3PowerApparentValue  = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.126'};
my $PhaseL3EnergyActiveValue   = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.127'};
my $PhaseL3EnergyApparentValue = $result->{'1.3.6.1.4.1.2606.7.4.2.2.1.10.2.129'};
$DEBUG and print qq|$PhaseL3VoltageDescName: $PhaseL3VoltageValue ($PhaseL3VoltageStatus)\n|;
$DEBUG and print qq|PhaseL3VoltageTHDValue: $PhaseL3VoltageTHDValue\n|;
$DEBUG and print qq|$PhaseL3CurrentDescName: $PhaseL3CurrentValue ($PhaseL3CurrentStatus)\n|;
$DEBUG and print qq|PhaseL3CurrentTHDValue: $PhaseL3CurrentTHDValue\n|;
$DEBUG and print qq|PhaseL3PowerFactorValue: $PhaseL3PowerFactorValue\n|;
$DEBUG and print qq|$PhaseL3PowerActiveDescName: $PhaseL3PowerActiveValue ($PhaseL3PowerActiveStatus)\n|;
$DEBUG and print qq|PhaseL3PowerReactiveValue: $PhaseL3PowerReactiveValue\n|;
$DEBUG and print qq|PhaseL3PowerApparentValue: $PhaseL3PowerApparentValue\n|;
$DEBUG and print qq|PhaseL3EnergyActiveValue: $PhaseL3EnergyActiveValue\n|;
$DEBUG and print qq|PhaseL3EnergyApparentValue: $PhaseL3EnergyApparentValue\n|;

if($PhaseL3VoltageStatus ne 'OK') {
  push(@EMesg, qq|L3: $PhaseL3VoltageStatus|);
}
if($PhaseL3CurrentStatus ne 'OK') {
  push(@EMesg, qq|L3: $PhaseL3CurrentStatus|);
}
if($PhaseL3PowerActiveStatus ne 'OK') {
  push(@EMesg, qq|L3: $PhaseL3PowerActiveStatus|);
}
$PhaseL3VoltageValue =~ s/ //g;
push(@PData, qq|'L3 Voltage'=$PhaseL3VoltageValue|);
$PhaseL3VoltageTHDValue =~ s/ //g;
push(@PData, qq|'L3 Voltage THD'=$PhaseL3VoltageTHDValue|);
$PhaseL3CurrentValue =~ s/ //g;
push(@PData, qq|'L3 Current'=$PhaseL3CurrentValue|);
$PhaseL3CurrentTHDValue =~ s/ //g;
push(@PData, qq|'L3 Current THD'=$PhaseL3CurrentTHDValue|);
push(@PData, qq|'L3 Power Factor'=$PhaseL3PowerFactorValue|);
$PhaseL3PowerActiveValue =~ s/ //g;
push(@PData, qq|'L3 Power Active'=$PhaseL3PowerActiveValue|);
$PhaseL3PowerReactiveValue =~ s/ //g;
push(@PData, qq|'L3 Power Reactive'=$PhaseL3PowerReactiveValue|);
$PhaseL3PowerApparentValue =~ s/ //g;
push(@PData, qq|'L3 Power Apparent'=$PhaseL3PowerApparentValue|);
$PhaseL3EnergyActiveValue =~ s/ //g;
push(@PData, qq|'L3 Energy Active'=$PhaseL3EnergyActiveValue|);
$PhaseL3EnergyApparentValue =~ s/ //g;
push(@PData, qq|'L3 Energy Apparent'=$PhaseL3EnergyApparentValue|);

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

my $pdata_output = join(' ', @PData);

my $check_status = EXIT_UNKNOWN;
my $check_output = 'UNKNOWN';
my $error_output = '';

if(@EMesg > 0) {
  $check_status = EXIT_WARNING;
  $check_output = 'WARNING';
  $error_output = join('. ',@EMesg);
  print qq|$check_output: $error_output \| $pdata_output\n|;
} else {
  $check_status = EXIT_OK;
  $check_output = 'OK';
  print qq|$check_output: Total Power Active is $TotalPowerActiveStatus \| $pdata_output\n|;
}

exit $check_status;

############################################################
1;
