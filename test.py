from serial import Serial
from micropyGPS import MicropyGPS

PORT = "/dev/serial0"
BAUD = 9600

gps = MicropyGPS(location_formatting='dd')

save_columns = [
        "lat",
        "lon",
        "kmph",
        "used_satellite",
        "timestamp",
        "date",
        "altitude",
        ]
f = open("./20250908test.log", "w")
f.write(",".join(save_columns))
f.close()

with Serial(PORT, BAUD, timeout=1) as ser:
    while True:
        f = open("./20250908test.log", "a")
        write_sentence = ""
        line = ser.readline()
        if not line.startswith(b"$"):
            continue
        for ch in line.decode("ascii", errors="ignore"):
            gps.update(ch)
        print("lat/lon(dd):", gps.latitude[0], gps.longitude[0])
        print("km/h:", gps.speed[2])
        
        write_sentence += f"{gps.latitude[0]},{gps.longitude[0]},"
        write_sentence += f"{gps.speed[2]},{'-'.join(str(x) for x in gps.satellites_used)},"
        write_sentence += f"{'-'.join(str(x) for x in gps.timestamp)},{'-'.join(str(x) for x in gps.date)},"
        write_sentence += f"{gps.altitude}"
        f.write(f"{write_sentence}\n")
