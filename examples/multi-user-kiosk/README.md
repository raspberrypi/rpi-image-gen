Build an image with two users, each with their own login session:

* `admin` (user1) logs into the Raspberry Pi desktop and has sudo access if a password is set
* `student` (user2) logs into Chromium running full screen in cage, and never has sudo access

The custom layer:

* Installs the Raspberry Pi desktop with its theme, icons, font and wallpaper, plus Chromium, cage and seatd
* Uses LightDM and the Raspberry Pi greeter, which the desktop already depends on
* Sets LightDM's session to `rpd-dispatch`, which starts Chromium in cage for members of the `kiosk` group and the Raspberry Pi desktop for everyone else

The config puts the student in the `kiosk` group. Since the session follows group membership, the student cannot choose the desktop instead. Members of the `kiosk` group are also denied SSH access.

seatd is installed and enabled because cage reaches the display through libseat, and the seatd socket is restricted to the `video` group. The config therefore adds `video` (and `render`, for GPU access in Chromium) to the student's groups.

Chromium's profile is created in the student's runtime directory, which is held in RAM and removed at logout. Every kiosk session therefore starts clean, with no history, cookies or logins left over from the last one.

Raspberry Pi Connect with Remote Update support is installed. If the image is provisioned, a device can be automatically onboarded into a Raspberry Pi Connect Organisation. Although this isn't an A/B image, otamaker payloads can still be delivered to perform remote management via scripted artefacts. A simple example use of this could be changing the kiosk URL (/etc/default/kiosk) so that the next time a student logs in, they get a different website.

To get back to the login screen from the kiosk, quit Chromium (for example with Ctrl+W). When it quits, cage exits too, which ends the session.

Both accounts are locked unless a password is supplied in the config or on the command line. For example:

```bash
rpi-image-gen build -S ./examples/multi-user-kiosk/ -c multi-user-kiosk.yaml -- \
   IGconf_device_user1pass='Adm1nPass!' IGconf_device_user2pass='Stud3ntPass!'
```

It may be preferred to pre-generate hashed passwords using `bin/genpasswd` against the chroot and set them in the config file, eg

```bash
device:
  user1passhash: $y$j9T$ut2T3ntwXKLfy8TLEda9B1$gtKyb2HIVLPUxLN///gXoPVvS4B/xGz/rbltqbVZpf0
  user2passhash: $y$j9T$l60hGlTauIdeaZQCBWluk.$K6Usw33XooZNcryYpAyKgz103zaz2UK4mcSMSlEpKQ3
```

Or better still, have no admin login at all and use Raspberry Pi Connect for all administrative duties (requires Connect auto-onboarding at provisioning time).
