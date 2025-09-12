import smbus2
import time

# I2Cの設定
bus = smbus2.SMBus(1)     # I²Cバス1
address = 0x1D            # アドレス（i2cdetectで確認）

# MMA8452Qレジスタ
WHO_AM_I = 0x0D
CTRL_REG1 = 0x2A
OUT_X_MSB = 0x01

# デバイス確認
whoami = bus.read_byte_data(address, WHO_AM_I)
print(f"WHO_AM_I: 0x{whoami:02X}")  # 0x2Aが返ればOK

# アクティブモードに設定
bus.write_byte_data(address, CTRL_REG1, 0x01)

def read_axis():
    data = bus.read_i2c_block_data(address, OUT_X_MSB, 6)
    x = ((data[0] << 8) | data[1]) >> 4
    y = ((data[2] << 8) | data[3]) >> 4
    z = ((data[4] << 8) | data[5]) >> 4
    # 12bit符号付き変換
    if x > 2047: x -= 4096
    if y > 2047: y -= 4096
    if z > 2047: z -= 4096
    return (x, y, z)

while True:
    x, y, z = read_axis()
    print(f"X={x}, Y={y}, Z={z}")
    time.sleep(0.5)
