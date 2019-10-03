Ping Probe Admin
====

Set of scripts to be make possible to admin pingprobe from ITM6 htem using executecommand.

Used to avoid mistakes from operators

Prerequisites
------

- ITM 6.2.3+
- tacmd login

Set Up
----

- [htem_pingprobeadmin.sh](htem_pingprobeadmin.sh) sould be placed into your Hub tem
  - Need to edit the varibles `RemoteScript` and `AG` to suits the environment.
- [pingprobeadmin.sh](pingprobeadmin.sh) and [pingprobeadmin.properties](pingprobeadmin.properties) need to be placed into the PingProbe Server
  - uncooment and configure the `pingprobeadmin.properties`


USAGE
---

```
<script> <opt> <Req Number> <Server FQN> <Cycle> <Location>
#
#       Example:
#       ./htem_pingprobeadmin.sh ADD REQ00XXXXXX SERVE.COM 300 "ASIA NORTH"
```

Options
----
(to be used only on script into the pingprobe)


- `add` # Add to ping probe monitoring function
- `remove` # remove from ping probe monitoring function
- `search` # search in ping probe monitoring function
- `watchdog_start` # start watchdog
- `start_PP_all` # start ping probe processes
- `stop_PP_all` # stop ping probe processes
