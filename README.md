# NAME

check_rittal_rcm.pl

# DESCRIPTION

Plugin for Icinga 2 (or Nagios) to check the status of Rittal RCM devices.

Residual Current Devices (RCD) are used for personal protection at electrical operating sites. In the event of a fault (the presence of a residual current), the voltage is switched off by the RCD.

Residual Current Monitoring (RCM) is used where RCD are not practical due to their disruptive nature. This will often be the case in a data center where high availability of services is sought. RCM devices monitor relevant electrical operating variables and signal anomalies, but without shutting down.

Rittal has a new series (introduced in 2021) of RCM devices on offer ("RCM Measuring Module/Inline Meter"). These are based on the well-known CMC3 and can be queried via SNMP.

This plugin queries the 3-phase version of the RCM for all operating variables of interest to us and outputs performance data. The complete list of OIDs is attached.


# SYNOPSIS

    check_rittal_rcm.pl -H <hostname> -C <SNMPv2-community>

# OPTIONS

    -?, --usage
      Print usage information
    -h, --help
      Print detailed help screen
    -V, --version
      Print version information
    --extra-opts=[section][@file]
      Read options from an ini file. See https://www.monitoring-plugins.org/doc/extra-opts.html
      for usage and examples.
    -H, --host=STRING
      hostname or IP address
    -s, --snmp_version=STRING
      SNMP version (1|2c|3)
    -C, --community=STRING
      SNMP community string
    -u, --username=STRING
      SNMPv3 Username
    --authpassword
      SNMPv3 authPassword
    --authkey
      SNMPv3 authKey
    --authprotocol
      SNMPv3 authProtocol
    --privpassword
      SNMPv3 privPassword
    --privkey
      SNMPv3 privKey
    --privprotocol
      SNMPv3 privProtocol
    -t, --timeout=INTEGER
      Seconds before plugin times out (default: 15)
    -v, --verbose
      Show details for command-line debugging (can repeat up to 3 times)

# SAMPLE OUTPUT

    RITTAL_RCM OK - Total.Power.Active.Value is 1881 W | Total.Frequency.Value=50Hz;; 'Total.Neutral Current.Value'=1.49A;; Total.Power.Active.Value=1881W;; Total.Energy.Active.Value=10577.5kWh;; Total.Energy.Active.Runtime.Value=25720388s;; 'Phase L1.Voltage.Value'=229.8V;; 'Phase L1.Voltage.THD.Value'=0%;; 'Phase L1.Current.Value'=3.44A;; 'Phase L1.Current.THD.Value'=0%;; 'Phase L1.Power.Factor.Value'=-0.97;; 'Phase L1.Power.Active.Value'=775W;; 'Phase L1.Power.Reactive.Value'=148var;; 'Phase L1.Power.Apparent.Value'=795VA;; 'Phase L1.Energy.Active.Value'=2681.3kWh;; 'Phase L1.Energy.Apparent.Value'=2759.5kVAh;; 'Phase L2.Voltage.Value'=230.4V;; 'Phase L2.Voltage.THD.Value'=0%;; 'Phase L2.Current.Value'=1.95A;; 'Phase L2.Current.THD.Value'=0%;; 'Phase L2.Power.Factor.Value'=-0.92;; 'Phase L2.Power.Active.Value'=417W;; 'Phase L2.Power.Reactive.Value'=157var;; 'Phase L2.Power.Apparent.Value'=448VA;; 'Phase L2.Energy.Active.Value'=3060.6kWh;; 'Phase L2.Energy.Apparent.Value'=3289.3kVAh;; 'Phase L3.Voltage.Value'=229.9V;; 'Phase L3.Voltage.THD.Value'=0%;; 'Phase L3.Current.Value'=3.09A;; 'Phase L3.Current.THD.Value'=0%;; 'Phase L3.Power.Factor.Value'=-0.96;; 'Phase L3.Power.Active.Value'=690W;; 'Phase L3.Power.Reactive.Value'=156var;; 'Phase L3.Power.Apparent.Value'=710VA;; 'Phase L3.Energy.Active.Value'=4835.6kWh;; 'Phase L3.Energy.Apparent.Value'=5002.5kVAh;; 'RCMs.RCM 01.AC.Value'=1.6mA;; 'RCMs.RCM 01.AC.SetPtHighAlarm'=0mA;; 'RCMs.RCM 01.AC.SetPtHighWarning'=0mA;; 'RCMs.RCM 01.DC.Value'=0.3mA;; 'RCMs.RCM 01.DC.SetPtHighAlarm'=0mA;; 'RCMs.RCM 01.DC.SetPtHighWarning'=0mA;;
