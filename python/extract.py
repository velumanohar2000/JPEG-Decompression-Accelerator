import struct
import math
from pathlib import Path
import sys

######## FILE I/O CONFIGURATION ###########
inputImg = sys.argv[1]
baseName = inputImg.split(".")[0]
srcImgPath = "../images/" + baseName + ".jpg"
resultDir = "out/" + baseName
######## OUTPUT FORMAT CONFIGURATION ###########
outputFormat = "bin32" #Options: "binary" = one long string, "bin32" = lines of 32 bits, "hex" = lines of 32 hex
################################################

####### Matrix Transformation Functions (Originally from functions.py) ###########
def convertFlatToNested(flatArray):
    """Convert a 1D array to a 2D square array"""
    dimension = int(math.sqrt(len(flatArray)))
    return [[element for element in flatArray[r*dimension:r*dimension+dimension]] for r in range(dimension)]

def convertNestedToFlat(nestedArray):
    """Convert a 2D array to a flat 1D array"""
    flatArray = []
    for row in nestedArray:
        flatArray.extend(row)
    return flatArray

####### BitStream Handling (Originally part of huffman.py) ###########
class BinaryDataStream:
    """Handle streaming bits from a binary string"""
    def __init__(self, binaryData):
        """Initialize with binary data string"""
        self.binaryData = binaryData
        self.currentIndex = 0

    def nextBit(self):
        """Get the next bit from the stream"""
        bit = self.binaryData[self.currentIndex]
        self.currentIndex += 1
        return int(bit)

    def nextBits(self, count):
        """Get the next N bits as a string"""
        result = ""
        for _ in range(count):
            result += str(self.nextBit())
        return result
    
    def isComplete(self):
        """Check if we've reached end of data"""
        return self.currentIndex >= len(self.binaryData)

####### Huffman Encoding/Decoding (Originally from huffman.py) ###########
class HuffmanCodec:
    """Implementation of Huffman encoding/decoding"""
    def __init__(self):
        self.treeStructure = []
        self.symbolTable = []
    
    def _buildTreeBranch(self, node, symbol, remainingDepth):
        """Helper function to build tree recursively"""
        if isinstance(node, list):
            if remainingDepth == 0:
                if len(node) < 2:
                    node.append(symbol)
                    return True                
                return False
            
            # Try to place in one of the branches
            for direction in [0, 1]:
                if len(node) == direction:
                    node.append([])
                if self._buildTreeBranch(node[direction], symbol, remainingDepth-1):
                    return True
        return False
    
    def constructTree(self, bitLengths, symbols):
        """Build Huffman tree from bit lengths and symbol values"""
        self.symbolTable = symbols
        symbolIndex = 0
        
        for bitLength in range(len(bitLengths)):
            for _ in range(bitLengths[bitLength]):
                self._buildTreeBranch(self.treeStructure, symbols[symbolIndex], bitLength)
                symbolIndex += 1

    def decodeSymbol(self, bitStream):
        """Decode a single symbol from the bit stream"""
        currentNode = self.treeStructure
        while isinstance(currentNode, list):
            bit = bitStream.nextBit()
            currentNode = currentNode[bit]
        return currentNode
    
    def getCompleteCode(self, bitStream):
        """Get a complete code from the stream"""
        while True:
            result = self.decodeSymbol(bitStream)
            if result == 0:
                return 0
            elif result != -1:
                return result
    
    def _findCodePath(self, node, targetSymbol):
        """Find the code path to a symbol in the tree"""
        # Check left branch
        if isinstance(node[0], list):
            path = self._findCodePath(node[0], targetSymbol)
            if path != "":
                return "0" + path
        elif node[0] == targetSymbol:
            return "0"
        
        # Check right branch
        if isinstance(node[1], list):
            path = self._findCodePath(node[1], targetSymbol)
            if path != "":
                return "1" + path
        elif node[1] == targetSymbol:
            return "1"
        
        return ""
    
    def generateCodeTable(self):
        """Generate a lookup table of codes and their values"""
        codeTable = [[], []]  # [Codes, Symbols]
        
        for symbol in self.symbolTable:
            code = self._findCodePath(self.treeStructure, symbol)
            if code:  # Only add if code was found
                codeTable[0].append(code)
                codeTable[1].append(symbol)
                
        return codeTable
    
    def exportTableToFile(self, filePath, reverseOrder=False):
        """Export the Huffman table to a file"""
        table = self.generateCodeTable()
        
        with open(filePath, "w") as f:
            if reverseOrder:
                f.write(str(len(table[0])) + '\n')
                for i in range(len(table[0])):
                    # Reverse the code bits
                    reversedCode = table[0][i][::-1]
                    f.write(f"{reversedCode} {table[1][i]} {len(table[0][i])}\n")
            else:
                for i in range(len(table[0])):
                    f.write(f"{table[0][i]} {table[1][i]} {len(table[0][i])}\n")
        
        return filePath

####### Binary Data Extraction Functions ###########
def extractBytes(dataBytes, currentPos, numBytes=1):
    """Extract 1 or 2 bytes from the data stream based on numBytes parameter"""
    if numBytes == 1:
        val, = struct.unpack(">B", dataBytes[currentPos:currentPos+1])
    else:
        val, = struct.unpack(">H", dataBytes[currentPos:currentPos+2])
    return (currentPos+numBytes, val)

def getHighNibble(byteValue):
    """Extract the high 4 bits from a byte"""
    return byteValue >> 4

def getLowNibble(byteValue):
    """Extract the low 4 bits from a byte"""
    return byteValue & 0x0F

####### Matrix Processing Functions ###########
def processMatrix(flatMatrix, displayOutput=False):
    """Process matrix data - optionally display it and convert from zigzag"""
    # Display if requested
    if displayOutput:
        for y in range(8):
            for x in range(8):
                print("%02d, " %(flatMatrix[x+y*8]), end="")
            print()
    
    # De-zigzag algorithm
    result = [[0 for _ in range(8)] for _ in range(8)]
    y, x, idx = 0, 0, 0
    traverseMode = "ascending"
    
    while True:
        result[y][x] = flatMatrix[idx]
        idx += 1
        
        if y == 7 and x == 7:
            break
        elif y == 0 and traverseMode == "ascending":
            x += 1
            traverseMode = "descending"
        elif x == 0 and traverseMode == "descending":
            y = y + 1 if y < 7 else y
            x = x + 1 if y == 7 else x
            traverseMode = "ascending"
        elif x == 7 and traverseMode == "ascending":
            y += 1
            traverseMode = "descending"
        elif y == 7 and traverseMode == "descending":
            x += 1
            traverseMode = "ascending"
        else:
            if traverseMode == "ascending":
                y -= 1
                x += 1
            else:  # descending
                y += 1
                x -= 1
    
    return convertNestedToFlat(result)

####### Bit Stream Extraction ###########
def extractBitStreamData(dataBytes, currentPos, formatType="binary"):
    """Extract bit stream with specified output format"""
    pos = currentPos
    resultStream = ""
    counter = 0  # Generic counter for bits or bytes
    
    while True:
        (pos, byteVal) = extractBytes(dataBytes, pos)
        
        if byteVal == 0xFF:
            (pos, nextByte) = extractBytes(dataBytes, pos)
            
            if nextByte == 0x00:
                # FF00 is stuffing byte pattern - keep the FF
                if formatType == "hex":
                    resultStream += 'FF'
                    counter += 1
                else:
                    resultStream += '11111111'
                    counter += 8
            elif nextByte == 0xD9:
                # Found EOI marker
                break
            else:
                print("Warning - 0xFF followed by unexpected value")
        else:
            if formatType == "hex":
                resultStream += f'{byteVal:02x}'
                counter += 1
            else:
                resultStream += f'{byteVal:08b}'
                counter += 8
        
        # Handle line breaks based on format
        if formatType == "hex" and counter >= 16:
            resultStream += '\n'
            counter = 0
        elif formatType == "bin32" and counter >= 32:
            resultStream += '\n'
            counter = 0
    
    return (pos-2, resultStream)

####### Main JPEG Processing Logic ############
def processJpegFile(filePath):
    """Process a JPEG file and extract its components"""
    # Read source image
    print("--Processing image: " + filePath + " --")
    with open(filePath, "rb") as f:
        dataBytes = f.read()
    
    # Setup data containers
    pos = 0  # Current position
    appMetadata = []
    unitTypeLabels = ["No Units/Pixel Aspect Ratio", "Pixels Per Inch", "Pixels per cm"]
    qTables = []
    huffCodeSizes = [[], []]  # [DC Tables, AC Tables]
    huffCodeValues = [[], []]  # [DC Tables, AC Tables]
    imgSize = []
    encodedData = ""
    
    # Verify JPEG signature
    (pos, fileSignature) = extractBytes(dataBytes, pos, 2)
    if fileSignature != 0xFFD8:
        print("Error: Not a valid JPEG file")
        return None
    
    print("SOI - Valid JPEG detected")
    
    # Process JPEG segments
    while True:
        (pos, markerPrefix) = extractBytes(dataBytes, pos)
        
        # Check for marker prefix 0xFF
        if markerPrefix != 0xFF:
            print(f"Error: Invalid marker structure at byte {hex(markerPrefix)}")
            continue
        
        # Get marker type
        (pos, markerType) = extractBytes(dataBytes, pos)
        
        if markerType == 0xE0:
            # APP0 segment
            print("App0 Segment - JFIF")
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            identifierText = ""
            endOfText = False
            
            for i in range(segmentLength-2):
                (pos, currentByte) = extractBytes(dataBytes, pos)
                if not endOfText:
                    if currentByte == 0:
                        endOfText = True
                    else:
                        identifierText += chr(currentByte)
                else:
                    appMetadata.append(currentByte)
            
            if identifierText == "JFIF":
                print(f"  {identifierText} Version: {appMetadata[0]}.{appMetadata[1]}")
                print(f"  Unit: {unitTypeLabels[appMetadata[2]]}")
                print(f"  Horizontal Pixel Density: {appMetadata[3]*256+appMetadata[4]}. " +
                      f"Vertical Pixel Density: {appMetadata[5]*256+appMetadata[6]}")
                print(f"  Thumbnail X: {appMetadata[7]}, Thumbnail Y: {appMetadata[8]}")
            else:
                print(f"Unsupported Application Segment: {identifierText}")
        
        elif markerType == 0xE1:
            print("App1 Segment - EXIF")
            quit()
        
        elif markerType == 0xDB:
            # Quantization Table segment
            print("Quantization Table Segment")
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            remainingBytes = segmentLength - 2
            
            while remainingBytes > 0:
                (pos, tableIndex) = extractBytes(dataBytes, pos)
                remainingBytes -= 1
                
                # Ensure we have enough slots in our tables array
                while len(qTables) < tableIndex + 1:
                    qTables.append([])
                
                # Read the 64 quantization values
                for i in range(64):
                    (pos, val) = extractBytes(dataBytes, pos)
                    remainingBytes -= 1
                    qTables[tableIndex].append(val)
                
                print(f"  Table Index: {tableIndex}")
                # Display and process in one step
                processMatrix(qTables[tableIndex], True)
        
        elif markerType == 0xC0:
            # Start of Frame - Baseline DCT
            print("Start of Frame - Baseline DCT")
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            (pos, precision) = extractBytes(dataBytes, pos)
            print(f"  Precision: {precision} bits")
            
            # Get image dimensions
            (pos, height) = extractBytes(dataBytes, pos, 2)
            (pos, width) = extractBytes(dataBytes, pos, 2)
            imgSize = (height, width)
            print(f"  Dimensions: {height} x {width} pixels")
            
            # Process channel information
            (pos, channelCount) = extractBytes(dataBytes, pos)
            for i in range(channelCount):
                (pos, channelId) = extractBytes(dataBytes, pos)
                print(f"  Channel ID: {channelId}")
                
                (pos, samplingFactors) = extractBytes(dataBytes, pos)
                horSampling = getHighNibble(samplingFactors)
                verSampling = getLowNibble(samplingFactors)
                print(f"  Horizontal Sampling: {horSampling}")
                print(f"  Vertical Sampling: {verSampling}")
                
                (pos, qtableId) = extractBytes(dataBytes, pos)
                print(f"  Q-Table ID: {qtableId}")
        
        elif markerType == 0xC2:
            print("Start of Frame - Progressive DCT")
            exit()
        
        elif markerType == 0xC4:
            # Huffman Table segment
            print("Huffman Table Definition")
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            (pos, tableInfo) = extractBytes(dataBytes, pos)
            
            # Get table class and ID
            tableClass = getHighNibble(tableInfo)
            tableId = getLowNibble(tableInfo)
            print(f"  Table Class: {tableClass}, Table ID: {tableId}")
            
            # Ensure we have enough slots in our tables arrays
            while len(huffCodeSizes[tableClass]) < tableId + 1:
                huffCodeSizes[tableClass].append([])
                huffCodeValues[tableClass].append([])
            
            # Read code length counts
            for i in range(16):
                (pos, codeCount) = extractBytes(dataBytes, pos)
                huffCodeSizes[tableClass][tableId].append(codeCount)
            
            # Read symbol values
            for i in range(segmentLength-2-1-16):
                (pos, codeValue) = extractBytes(dataBytes, pos)
                huffCodeValues[tableClass][tableId].append(codeValue)
            
            print(f"  Code counts by length (1-16): {huffCodeSizes[tableClass][tableId]}")
            print(f"  Symbol values: {huffCodeValues[tableClass][tableId]}")
        
        elif markerType == 0xFE:
            # Comment segment
            print("Comment Segment")
            commentText = "  "
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            
            for i in range(segmentLength-2):
                (pos, currentByte) = extractBytes(dataBytes, pos)
                commentText += chr(currentByte)
            
            print(commentText)
        
        elif markerType == 0xDA:
            # Start of Scan segment
            print("Start of Scan")
            (pos, segmentLength) = extractBytes(dataBytes, pos, 2)
            (pos, compCount) = extractBytes(dataBytes, pos)
            
            scanType = "Interleaved" if compCount > 1 else "Non-Interleaved"
            print(f"  Components in scan: {compCount} ({scanType})")
            
            # Process each component
            for i in range(compCount):
                (pos, compId) = extractBytes(dataBytes, pos)
                (pos, tableMappings) = extractBytes(dataBytes, pos)
                
                dcTableId = getLowNibble(tableMappings)
                acTableId = getHighNibble(tableMappings)
                
                print(f"  Component ID: {compId}")
                print(f"  DC Table ID: {dcTableId}")
                print(f"  AC Table ID: {acTableId}")
            
            # Spectral selection and successive approximation
            (pos, startPos) = extractBytes(dataBytes, pos)
            print(f"  Spectral selection start: {startPos}")
            
            (pos, endPos) = extractBytes(dataBytes, pos)
            print(f"  Spectral selection end: {endPos}")
            
            (pos, approxBits) = extractBytes(dataBytes, pos)
            approxHigh = getLowNibble(approxBits)
            approxLow = getHighNibble(approxBits)
            print(f"  Approx bit high: {approxHigh}")
            print(f"  Approx bit low: {approxLow}")
            
            # Extract compressed image data based on format
            (pos, encodedData) = extractBitStreamData(dataBytes, pos, outputFormat)
            
        elif markerType == 0xD9:
            print("End of Image")
            break
        
        else:
            print(f"Unknown marker: {hex(markerType)}")
    
    return {
        "size": imgSize,
        "qTables": qTables,
        "huffDC": {
            "sizes": huffCodeSizes[0],
            "values": huffCodeValues[0]
        },
        "huffAC": {
            "sizes": huffCodeSizes[1], 
            "values": huffCodeValues[1]
        },
        "encodedData": encodedData
    }

####### Output Processing Functions ############
def saveOutputFiles(extractedData, outDir):
    """Save extracted components to output files"""
    # Create output directory
    Path(outDir).mkdir(parents=True, exist_ok=True)
    
    # Save encoded data (normal and reversed)
    bitStreamPath = f"{outDir}/bitStream.txt"
    with open(bitStreamPath, "w") as f:
        f.write(extractedData["encodedData"])
    print(f"Encoded data written to: {bitStreamPath}")
    
    # Save reversed bitstream
    reversedPath = f"{outDir}/bitStreamFlipped.txt"
    with open(reversedPath, "w") as f:
        for line in extractedData["encodedData"].split("\n"):
            f.write(line[::-1] + "\n")
    print(f"Reversed encoded data written to: {reversedPath}")
    
    # Process Huffman tables
    for tableType, prefix in [("DC", extractedData["huffDC"]), ("AC", extractedData["huffAC"])]:
        for i in range(len(prefix["sizes"])):
            huffCodec = HuffmanCodec()
            huffCodec.constructTree(prefix["sizes"][i], prefix["values"][i])
            
            # Regular table
            tablePath = f"{outDir}/{tableType}_HuffTable_Index{i}.txt"
            huffCodec.exportTableToFile(tablePath)
            print(f"{tableType} Huffman table written to: {tablePath}")
            
            # Flipped table
            flippedPath = f"{outDir}/{tableType}_HuffTable_Index{i}Flipped.txt"
            huffCodec.exportTableToFile(flippedPath, True)
            print(f"Reversed {tableType} Huffman table written to: {flippedPath}")
    
    # Save quantization tables
    for i, table in enumerate(extractedData["qTables"]):
        tablePath = f"{outDir}/QuantTable{i}.txt"
        normalizedTable = processMatrix(table)
        
        with open(tablePath, "w") as f:
            for row in range(8):
                f.write(str(normalizedTable[row*8:row*8+8])[1:-1] + "\n")
        
        print(f"Quantization table written to: {tablePath}")
    
    # Save image metadata
    metadataPath = f"{outDir}/HeaderInfo.txt"
    with open(metadataPath, "w") as f:
        f.write(f"{extractedData['size'][0]},{extractedData['size'][1]}\n")
    print(f"Image metadata written to: {metadataPath}")
    
    # Cache image name for subsequent processing
    with open("imageName.txt", "w") as f:
        f.write(f"{baseName}\n")
    print(f"Image name {baseName} cached to: imageName.txt")

####### Main Execution ############
if __name__ == "__main__":
    # Run the extraction process
    jpegData = processJpegFile(srcImgPath)

    # Save the results
    if jpegData:
        saveOutputFiles(jpegData, resultDir)
    else:
        print("Processing failed. No output files created.")