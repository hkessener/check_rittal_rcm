# NAME

check_rittal_rcm.pl

# DESCRIPTION

Plugin for Icinga 2 (or Nagios) to check the status of Rittal RCM devices.

**No longer maintained and superseeded by check_rittal_pdu, see my other repository.**

Residual Current Devices (RCD) are used for personal protection at electrical operating sites. In the event of a fault (the presence of a residual current), the voltage is switched off by the RCD.

Residual Current Monitoring (RCM) is used where RCD are not practical due to their disruptive nature. This will often be the case in a data center where high availability of services is sought. RCM devices monitor relevant electrical operating variables and signal anomalies, but without shutting down.

Rittal has a new series (introduced in 2021) of RCM devices on offer ("RCM Measuring Module/Inline Meter"). These are part of the PDU line and can be queried via SNMP.

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

    RITTAL_RCM OK - Total_Power_Active is 4969 W | Total_Frequency=50Hz;;;0;650 Total_Neutral_Current=5.8A;0:0;0:0;0;3500 Total_Power_Active=4969W;0:0;0:0;0;27300 Total_Energy_Active=28297.5kWh;;;0;2000000000 Total_Energy_Active_Runtime=59881700s;;;0;2000000000 L1_Voltage=232.5V;210:250;200:260;0;4000 L1_Voltage_THD=0%;;;0;400 L1_Current=5.09A;0:0;0:0;0;3500 L1_Current_THD=0%;;;0;400 L1_Power_Factor=-0.99;;;-100;100 L1_Power_Active=1181W;0:0;0:0;0;9100 L1_Power_Reactive=114var;;;0;9100 L1_Power_Apparent=1181VA;;;0;9100 L1_Energy_Active=7326.9kWh;;;0;2000000000 L1_Energy_Apparent=7436.2kVAh;;;0;2000000000 L2_Voltage=232.2V;210:250;200:260;0;4000 L2_Voltage_THD=0%;;;0;400 L2_Current=5.43A;0:0;0:0;0;3500 L2_Current_THD=0%;;;0;400 L2_Power_Factor=-0.99;;;-100;100 L2_Power_Active=1256W;0:0;0:0;0;9100 L2_Power_Reactive=65var;;;0;9100 L2_Power_Apparent=1258VA;;;0;9100 L2_Energy_Active=9412.3kWh;;;0;2000000000 L2_Energy_Apparent=9470.6kVAh;;;0;2000000000 L3_Voltage=233.5V;210:250;200:260;0;4000 L3_Voltage_THD=0%;;;0;400 L3_Current=10.89A;0:0;0:0;0;3500 L3_Current_THD=0%;;;0;400 L3_Power_Factor=-0.99;;;-100;100 L3_Power_Active=2537W;0:0;0:0;0;9100 L3_Power_Reactive=143var;;;0;9100 L3_Power_Apparent=2540VA;;;0;9100 L3_Energy_Active=11558.3kWh;;;0;2000000000 L3_Energy_Apparent=11615.8kVAh;;;0;2000000000 RCMs_RCM_01_AC=1.6mA;;;0;1000 RCMs_RCM_01_DC=0.1mA;;;0;1000
