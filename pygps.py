from serial import Serial
from micropyGPS import MicropyGPS

PORT = "/dev/serial0"
BAUD = 9600

gps = MicropyGPS(location_formatting='dd')

with Serial(PORT, BAUD, timeout=1) as ser:
    while True:
        line = ser.readline()
        if not line.startswith(b"$"):
            continue
        for ch in line.decode("ascii", errors="ignore"):
            gps.update(ch)
        print("lat/lon(dd):", gps.latitude[0], gps.longitude[0])
        print("km/h:", gps.speed[2])
