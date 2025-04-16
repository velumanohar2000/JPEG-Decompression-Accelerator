import sys
from pathlib import Path

######## USER - ENTER I/O FILE NAMES ###########
imageName = sys.argv[1]                     # e.g., "charcoal_cat"
imageName = imageName.split(".")[0]         # Remove extension if present
imgName = f"../images/{imageName}.jpg"      # Image path

######## USER - CONFIGURE PARAMETERS ###########
outType = "bin32"  # Options: "binary", "bin32", "hex"

def bytes_to_words(data, word_size=4):
    while len(data) % word_size != 0:
        data += b'\x00'
    words = []
    for i in range(0, len(data), word_size):
        word = int.from_bytes(data[i:i+word_size], byteorder='big')
        words.append(word)
    return words

def write_svh(words, mode, out_path, array_name="jpeg_data"):
    count = len(words)

    with open(out_path, 'w') as f:
        f.write(f"// Auto-generated .svh containing JPEG data ({mode})\n")
        f.write(f"`define DATA_SEGMENTS {count}\n")
        f.write(f"logic [31:0] {array_name} [0:`DATA_SEGMENTS-1] = '{{\n")

        for i, word in enumerate(words):
            comma = "," if i != count - 1 else ""

            if mode == "binary":
                bin_str = f"{word:032b}"
                f.write(f"    32'b{bin_str}{comma}\n")

            elif mode in ("bin32", "hex"):
                f.write(f"    32'h{word:08X}{comma}\n")

            else:
                raise ValueError(f"Unsupported output mode: {mode}")

        f.write("};\n")

# ---- Main Execution ----
def main():
    input_path = Path(imgName)
    if not input_path.exists():
        print(f"Error: File not found at {input_path.resolve()}")
        sys.exit(1)

    # Read image
    with open(input_path, "rb") as f:
        data = f.read()

    words = bytes_to_words(data)

    # CORRECTED PATH: exactly one folder up and into verilog/
    out_path = Path("/home/mbutton/jpeg/verilog/segmented_raw.svh")
    print(f"Saving output to: {out_path.resolve()}")

    write_svh(words, outType, out_path)
    print(f"Generated {out_path} with {len(words)} 32-bit words in '{outType}' format.")


if __name__ == "__main__":
    main()
