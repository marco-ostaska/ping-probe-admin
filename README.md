Ping Probe Admin
====

The Ping Probe Admin is a set of scripts that allow you to manage the ping probe process on an ITM 6.2.3+ system. It is designed to help operators avoid mistakes when working with the ping probe process.

Prerequisites
------

To use the Ping Probe Admin, you will need:

- ITM 6.2.3+
- tacmd login

Set Up
----

- Place the [htem_pingprobeadmin.sh](htem_pingprobeadmin.sh) script in your Hub tem.
- Edit the RemoteScript and AG variables in the [pingprobeadmin.sh](pingprobeadmin.sh) script to match your environment.
- Place the [pingprobeadmin.sh](pingprobeadmin.sh) and [pingprobeadmin.properties](pingprobeadmin.properties) files on the PingProbe Server.
  - Uncomment and configure the pingprobeadmin.properties file.


USAGE
---

To use the Ping Probe Admin, run the htem_pingprobeadmin.sh script with the following syntax:

```
<script> <opt> <Req Number> <Server FQN> <Cycle> <Location>
#
#       Example:
#       ./htem_pingprobeadmin.sh ADD REQ00XXXXXX SERVE.COM 300 "ASIA NORTH"
```

Options
----

The following options are available when running the pingprobeadmin.sh script on the PingProbe Server:

- **add**: Add a server to the ping probe monitoring function.
- **remove**:  Remove a server from the ping probe monitoring function.
- **search**: Search for a server in the ping probe monitoring function.
- **watchdog_start**:  Start the watchdog process.
- **start_PP_all:** Start all ping probe processes.
- **stop_PP_all:** Stop all ping probe processes.

- `add` # Add to ping probe monitoring function
- `remove` # remove from ping probe monitoring function
- `search` # search in ping probe monitoring function
- `watchdog_start` # start watchdog
- `start_PP_all` # start ping probe processes
- `stop_PP_all` # stop ping probe processes

Note: The options above should only be used on the pingprobeadmin.sh script on the PingProbe Server.

Troubleshooting
----


- Check the logs: The Ping Probe Admin writes log messages to various log files, which can be helpful in understanding the cause of any issues. Check the logs on the PingProbe Server and the Hub tem to see if there are any error messages that can help identify the problem.
- Check the syntax: Make sure that you are using the correct syntax when running the htem_pingprobeadmin.sh script. Double-check that you are using the correct options and providing all required arguments.
- Check the configuration: Make sure that the pingprobeadmin.properties file is properly configured and that all required variables are set correctly.
- Check the permissions: Make sure that you have the necessary permissions to run the Ping Probe Admin scripts. The htem_pingprobeadmin.sh script should be run as an operator, while the pingprobeadmin.sh script should be run as root.
