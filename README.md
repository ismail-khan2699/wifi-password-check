# wifi-password-check
A small automation script that tests likely typo variations of a Wi-Fi password against a target network. It was built for situations where a password was accidentally saved with duplicated or repeated digits during setup, helping quickly identify the working password without manually trying every combination.

## Why this script exists
This script exists because I managed to fumble a Wi-Fi password change in the most elite way possible.

I was updating my router password to `0123456789` and my keyboard apparently decided it wanted creative freedom. Somewhere in the process, one of the digits got duplicated or even tripled(the keyboard missfires sometime). Could’ve been `33`, `111`, `777`, who knows. The result? Every device in the house instantly lost connection and I was sitting there like what a headache.

Instead of manually trying every cursed variation one by one like a caveman, I made this script to automatically test possible combinations against the Wi-Fi network until it finds the one that actually works.

So yeah, this entire thing was born from one extra digit and a severe lack of patience.

