# NAME

check_rittal_rcm.pl

# DESCRIPTION

Plugin for Icinga 2 (or Nagios) to check the status of Rittal RCM devices.

Residual Current Devices (RCD) are used for personal protection at electrical operating sites. In the event of a fault (the presence of a residual current), the voltage is switched off by the RCD.

Residual Current Monitoring (RCM) is used where RCDs are not practical due to their disruptive nature. This will often be the case in a data center where high availability of services is sought. RCMs monitor relevant electrical operating variables and signal anomalies, but without shutting down.

Rittal has a new series (introduced in 2021) of RCMs on offer ("RCM Measuring Module -- Inline Meter"). These are based on the well-known CMC3 and can be queried via SNMP.

This plugin is in a very early status, but functional. It queries the 3-phase version of the RCM for all operating variables of interest to us and outputs performance data. The corresponding list of OIDs is attached.


# SYNOPSIS

    check_rittal_rcm.pl -H <hostname> -C <SNMPv2-community>

# OPTIONS

    none yet

# SAMPLE OUTPUT

OK: Total Power Active is 1857W | 'Total Frequency'=50.0Hz 'Total Neutral Current'=1.39A 'Total Power Active'=1857W 'Total Energy Active'=10261.5kWh 'Total Energy Active Runtime'=25106183s 'L1 Voltage'=229.7V 'L1 Voltage THD'=0% 'L1 Current'=3.41A 'L1 Current THD'=6% 'L1 Power Factor'=-0.98  'L1 Power Active'=768W 'L1 Power Reactive'=149var 'L1 Power Apparent'=787VA 'L1 Energy Active'=2551.9kWh 'L1 Energy Apparent'=2627.4kVAh 'L2 Voltage'=230.4V 'L2 Voltage THD'=0% 'L2 Current'=1.99A 'L2 Current THD'=12% 'L2 Power Factor'=-0.93  'L2 Power Active'=428W 'L2 Power Reactive'=154var 'L2 Power Apparent'=459VA 'L2 Energy Active'=2988.3kWh 'L2 Energy Apparent'=3211.7kVAh 'L3 Voltage'=230.0V 'L3 Voltage THD'=0% 'L3 Current'=3.00A 'L3 Current THD'=11% 'L3 Power Factor'=-0.96  'L3 Power Active'=663W 'L3 Power Reactive'=157var 'L3 Power Apparent'=685VA 'L3 Energy Active'=4721.3kWh 'L3 Energy Apparent'=4884.2kVAh 'RCM AC value'=1.3mA 'RCM AC Setpoint High Alarm'=0.0mA 'RCM AC Setpoint High Warn'=0.0mA 'RCM DC value'=0.3mA 'RCM DC Setpoint High Alarm'=0.0mA 'RCM DC Setpoint High Warn'=0.0mA
