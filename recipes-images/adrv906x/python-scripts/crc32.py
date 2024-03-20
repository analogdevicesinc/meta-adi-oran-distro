import zlib
import sys

BUFFER_SIZE=8192

def get_crc32(path):
    with open(path, 'rb') as f:
        crc = 0
        while True:
            data = f.read(BUFFER_SIZE)
            if not data:
                break
            crc = zlib.crc32(data, crc)
    return crc

def main():
    for f in sys.argv[1:]:
        crc32 = get_crc32(f)
        crc32hex = hex(crc32)[2:]
        print(f'{crc32hex}')

if __name__ == '__main__':
    main()