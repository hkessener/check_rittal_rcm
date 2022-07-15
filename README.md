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

    RITTAL_RCM OK - Total.Power.Active.Value is 1845 W | Total.Frequency.Value=50Hz;;;0;650 'Total.Neutral Current.Value'=1.42A;0:0;0:0;0;3500 Total.Power.Active.Value=1845W;0:0;0:0;0;27300 Total.Energy.Active.Value=10663.8kWh;;;0;2000000000 Total.Energy.Active.Runtime.Value=25885944s;;;0;2000000000 'Phase L1.Voltage.Value'=229.7V;210:250;200:260;0;4000 'Phase L1.Voltage.THD.Value'=0%;;;0;400 'Phase L1.Current.Value'=3.44A;0:0;0:0;0;3500 'Phase L1.Current.THD.Value'=0%;;;0;400 'Phase L1.Power.Factor.Value'=-0.97;;;-100;100 'Phase L1.Power.Active.Value'=776W;0:0;0:0;0;9100 'Phase L1.Power.Reactive.Value'=148var;;;0;9100 'Phase L1.Power.Apparent.Value'=790VA;;;0;9100 'Phase L1.Energy.Active.Value'=2717.2kWh;;;0;2000000000 'Phase L1.Energy.Apparent.Value'=2796.1kVAh;;;0;2000000000 'Phase L2.Voltage.Value'=230.5V;210:250;200:260;0;4000 'Phase L2.Voltage.THD.Value'=0%;;;0;400 'Phase L2.Current.Value'=1.95A;0:0;0:0;0;3500 'Phase L2.Current.THD.Value'=0%;;;0;400 'Phase L2.Power.Factor.Value'=-0.93;;;-100;100 'Phase L2.Power.Active.Value'=420W;0:0;0:0;0;9100 'Phase L2.Power.Reactive.Value'=156var;;;0;9100 'Phase L2.Power.Apparent.Value'=450VA;;;0;9100 'Phase L2.Energy.Active.Value'=3080kWh;;;0;2000000000 'Phase L2.Energy.Apparent.Value'=3310.1kVAh;;;0;2000000000 'Phase L3.Voltage.Value'=230V;210:250;200:260;0;4000 'Phase L3.Voltage.THD.Value'=0%;;;0;400 'Phase L3.Current.Value'=2.96A;0:0;0:0;0;3500 'Phase L3.Current.THD.Value'=0%;;;0;400 'Phase L3.Power.Factor.Value'=-0.96;;;-100;100 'Phase L3.Power.Active.Value'=655W;0:0;0:0;0;9100 'Phase L3.Power.Reactive.Value'=157var;;;0;9100 'Phase L3.Power.Apparent.Value'=676VA;;;0;9100 'Phase L3.Energy.Active.Value'=4866.6kWh;;;0;2000000000 'Phase L3.Energy.Apparent.Value'=5034.4kVAh;;;0;2000000000 'RCMs.RCM 01.AC.Value'=1.6mA;;;0;1000 'RCMs.RCM 01.DC.Value'=0.3mA;;;0;1000
