#
#  generate_images.sh
#  Tranquil
#
#  Created by Dana Buehre on 3/27/22.
#

# Generate 1x, 2x images for a directory containing 3x png files
# example usage: ./generate_images.sh -s ./Image-Assets -o . -c ./Resources

while getopts s:o: flag
do
    case "${flag}" in
        s) sourceDirectory=$(echo ${OPTARG} | sed 's:/*$::');;
        o) outputDirectory=$(echo ${OPTARG} | sed 's:/*$::');;
        *)
    esac
done

if [ -z ${sourceDirectory+x} ]; then echo "no source directory set"; exit; fi
if [ -z ${outputDirectory+x} ]; then echo "no output directory set, using sourceDirectory"; outputDirectory="$sourceDirectory"; fi
if [ ! -d "$sourceDirectory" ]; then echo "source directory doesn't exist"; exit; fi

# Create the output directory if it doesn't exist
mkdir -p "$outputDirectory"

for f in "$sourceDirectory"/*.png
do
  # Get the name of the file from the path
  fileName="${f##*/}";

  # Get the file name without extension
  baseName=$(echo "$fileName" | cut -d'.' -f1)

  # Path to the working copy of the original image
  workingCopy="$sourceDirectory/_$fileName"

	# Create a copy of the original file
	cp "$f" "$workingCopy"

	# Set proper resolution to working copy
  sips -s dpiHeight 72.0 -s dpiWidth 72.0 "$workingCopy"

  # Create 1x, 2x, 3x, image copies in the output folder
  cp "$workingCopy" "$outputDirectory/$baseName@3x.png"
  cp "$workingCopy" "$outputDirectory/$baseName@2x.png"
  cp "$workingCopy" "$outputDirectory/$baseName.png"

	# Get Width of original file
	xWIDTH=$(sips -g pixelWidth "$workingCopy" | cut -d':' -f 2 | tail -1 | cut -d' ' -f 2)

	# Get Height of original file
	xHEIGHT=$(sips -g pixelHeight "$workingCopy" | cut -d':' -f 2 | tail -1 | cut -d' ' -f 2)

	# Variables for 1x
	xWIDTH1=$(expr $xWIDTH / 3)
	xHEIGHT1=$(expr $xHEIGHT / 3)

	# Variables for 2x
	xWIDTH2=`expr $xWIDTH1 \* 2`
	xHEIGHT2=`expr $xHEIGHT1 \* 2`

	# Apply size to images
	sips -z "$xHEIGHT1" "$xWIDTH1" "$outputDirectory/$fileName"
	sips -z "$xHEIGHT2" "$xWIDTH2" "$outputDirectory/$baseName@2x.png"

	rm "$workingCopy"

done

exit 1;