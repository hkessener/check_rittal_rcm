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

    RITTAL_RCM OK - Total Power Active Value is 3996 W | 'Total Frequency Value'=50Hz;;;0;650 'Total Neutral Current Value'=5.65A;0:0;0:0;0;3500 'Total Power Active Value'=3996W;0:0;0:0;0;27300 'Total Energy Active Value'=11559kWh;;;0;2000000000 'Total Energy Active Runtime Value'=46088379s;;;0;2000000000 'Phase L1 Voltage Value'=230.1V;210:250;200:260;0;4000 'Phase L1 Voltage THD Value'=0%;;;0;400 'Phase L1 Current Value'=4.05A;0:0;0:0;0;3500 'Phase L1 Current THD Value'=0%;;;0;400 'Phase L1 Power Factor Value'=-0.99;;;-100;100 'Phase L1 Power Active Value'=924W;0:0;0:0;0;9100 'Phase L1 Power Reactive Value'=81var;;;0;9100 'Phase L1 Power Apparent Value'=935VA;;;0;9100 'Phase L1 Energy Active Value'=3235.1kWh;;;0;2000000000 'Phase L1 Energy Apparent Value'=3539.1kVAh;;;0;2000000000 'Phase L2 Voltage Value'=230.2V;210:250;200:260;0;4000 'Phase L2 Voltage THD Value'=0%;;;0;400 'Phase L2 Current Value'=3.86A;0:0;0:0;0;3500 'Phase L2 Current THD Value'=0%;;;0;400 'Phase L2 Power Factor Value'=-0.99;;;-100;100 'Phase L2 Power Active Value'=871W;0:0;0:0;0;9100 'Phase L2 Power Reactive Value'=69var;;;0;9100 'Phase L2 Power Apparent Value'=876VA;;;0;9100 'Phase L2 Energy Active Value'=5612.3kWh;;;0;2000000000 'Phase L2 Energy Apparent Value'=5636.4kVAh;;;0;2000000000 'Phase L3 Voltage Value'=229.7V;210:250;200:260;0;4000 'Phase L3 Voltage THD Value'=0%;;;0;400 'Phase L3 Current Value'=9.48A;0:0;0:0;0;3500 'Phase L3 Current THD Value'=0%;;;0;400 'Phase L3 Power Factor Value'=-0.99;;;-100;100 'Phase L3 Power Active Value'=2171W;0:0;0:0;0;9100 'Phase L3 Power Reactive Value'=115var;;;0;9100 'Phase L3 Power Apparent Value'=2170VA;;;0;9100 'Phase L3 Energy Active Value'=2711.6kWh;;;0;2000000000 'Phase L3 Energy Apparent Value'=2730.8kVAh;;;0;2000000000 'RCMs RCM 01 AC Value'=0.9mA;;;0;1000 'RCMs RCM 01 DC Value'=0mA;;;0;1000
