#
#  generate_assets.sh
#  Tranquil
#
#  Created by Dana Buehre on 3/20/22.
#

# based on https://gist.github.com/sag333ar/bf55ac27c6ffa5fd2ee72fd4f5b79fe9
# Generate Assets.xcassets for a directory containing 3x png files
# example usage: ./generate_assets.sh -s Image-Assets -o . -c Resources

while getopts s:o:c: flag
do
    case "${flag}" in
        s) sourceDirectory=$(echo ${OPTARG} | sed 's:/*$::');;
        o) outputDirectory=$(echo ${OPTARG} | sed 's:/*$::');;
        c) compileDirectory=$(echo ${OPTARG} | sed 's:/*$::');;
        *)
    esac
done

if [ -z ${sourceDirectory+x} ]; then echo "no source directory set"; exit; fi
if [ -z ${outputDirectory+x} ]; then echo "no output directory set, using sourceDirectory"; outputDirectory="$sourceDirectory"; fi
if [ -z ${compileDirectory+x} ]; then echo "no source directory set, using outputDirectory"; compileDirectory="$outputDirectory"; fi
if [ ! -d "$sourceDirectory" ]; then echo "source directory doesn't exist"; exit; fi

assetsDirectory="$outputDirectory/Assets.xcassets"

rm -rf "$assetsDirectory"
mkdir -p "$assetsDirectory"

assetsContent=$(cat <<-____HERE
{
  "info" : {
    "author" : "xcode",
    "version" : 1
   }
}
____HERE
)

printf '%s' "$assetsContent" >> "$assetsDirectory/Contents.json"

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

  # Creating Asset folder
  mkdir -p "$assetsDirectory/$baseName.imageset"

  # Create 1x, 2x, 3x, image copies in the asset folder
  cp "$workingCopy" "$assetsDirectory/$baseName.imageset/$baseName@3x.png"
  cp "$workingCopy" "$assetsDirectory/$baseName.imageset/$baseName@2x.png"
  cp "$workingCopy" "$assetsDirectory/$baseName.imageset/$baseName.png"

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
	sips -z "$xHEIGHT1" "$xWIDTH1" "$assetsDirectory/$baseName.imageset/$fileName"
	sips -z "$xHEIGHT2" "$xWIDTH2" "$assetsDirectory/$baseName.imageset/$baseName@2x.png"

	rm "$workingCopy"

  imagesetContent=$(cat <<-____HERE
{
  "images" : [
    {
      "filename" : "${baseName}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${baseName}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${baseName}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "compression-type" : "lossless"
  }
}
____HERE
  )

	printf '%s' "$imagesetContent" >> "${assetsDirectory}/${baseName}.imageset/Contents.json"

done

/usr/bin/xcrun actool "$assetsDirectory" --compile "$compileDirectory" --platform iphoneos --minimum-deployment-target 11.0 &> /dev/null

exit 1;