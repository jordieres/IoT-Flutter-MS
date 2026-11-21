# HealthyWear Sensoria settings

Open `https://apiict03.etsii.upm.es/healthywear/` to reach the password protected editor at `/healthywear/admin`. Choose a range and sampling rate for each sensor. The separate packet period controls the Bluetooth stream (20 ms is 50 packets per second). “Keep device setting” leaves that rate or period alone. Changes take effect on the next connection. The app reads the validated profile at `/healthywear/sensoria-settings.json` and uses its last valid profile or its built-in defaults offline.

The editor service runs on apiict03 at `127.0.0.1:8097` under the `amirf` account. To set the editor password, sign into the server and run:

```sh
python3 ~/healthywear/sensoria_admin.py --set-password
```

The editor username is `admin`. To try it before the public route is enabled, open an SSH tunnel from your Mac and visit [the editor through the tunnel](http://localhost:8097/healthywear/admin):

```sh
ssh -N -L 8097:127.0.0.1:8097 amirf@apiict03.etsii.upm.es
```

The Nginx publisher can install or update the route on apiict03. From your Mac, run the following to choose the editor password and publish the route. Enter the server sudo password only when prompted by the terminal.

```sh
ssh -t amirf@apiict03.etsii.upm.es 'python3 ~/healthywear/sensoria_admin.py --set-password && sudo /usr/bin/python3 ~/healthywear/publish_healthywear_nginx.py'
```

To review the Nginx change beforehand, run `python3 ~/healthywear/publish_healthywear_nginx.py --preview` on apiict03. The publisher backs up the site and restores it if Nginx fails validation or reload. After publication, the HTTPS settings URL should return JSON and the editor should require sign in. The app already uses the matching HTTPS URL.

## Sensoria commands

The sensor command groups are `03 01` (accelerometer), `03 02` (gyroscope), and `03 03` (magnetometer). Within each group, `01` reads the rate, `02` writes the rate, `03` reads the range, and `04` writes the range. Writes append the numeric value as two big endian bytes. For example, `03 01 02 00 68` requests 104 Hz. This is independent of the Bluetooth packet period, which is stored in channel 0 settings. The app reads changed settings back in the same connection. It does not routinely reboot the Core after rate or range writes. Magnetometer calibration uses the separate guided flow and waits for the device result.

Before a study rollout, verify any selected sampling rate on a spare Core and compare the packet cadence against your study protocol. The sampling and range selections configure the Core. The laboratory bias, scale, and pressure calibration in Joaquín's protocol is a separate procedure.
