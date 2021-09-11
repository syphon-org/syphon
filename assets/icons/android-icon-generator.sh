#!/bin/sh
 
#cleanup previous icons
DIR_TO_SAVE_ICONS=$PWD/android
rm -rf $DIR_TO_SAVE_ICONS
ICON_NAME=$1 #take icon name as first argument

echo "Creating android icons of different dimensions for $ICON_NAME"

mkdir -p $DIR_TO_SAVE_ICONS/drawable-xxxhdpi/
mkdir -p $DIR_TO_SAVE_ICONS/drawable-xxhdpi/
mkdir -p $DIR_TO_SAVE_ICONS/drawable-xhdpi/
mkdir -p $DIR_TO_SAVE_ICONS/drawable-hdpi/
mkdir -p $DIR_TO_SAVE_ICONS/drawable-mdpi/
mkdir -p $DIR_TO_SAVE_ICONS/drawable-ldpi/

convert $ICON_NAME -resize 192x192 $DIR_TO_SAVE_ICONS/drawable-xxxhdpi/ic_launcher.png
convert $ICON_NAME -resize 192x192 $DIR_TO_SAVE_ICONS/drawable-xxxhdpi/ic_launcher_round.png
convert $ICON_NAME -resize 144x144 $DIR_TO_SAVE_ICONS/drawable-xxhdpi/ic_launcher.png
convert $ICON_NAME -resize 144x144 $DIR_TO_SAVE_ICONS/drawable-xxhdpi/ic_launcher_round.png
convert $ICON_NAME -resize 96x96 $DIR_TO_SAVE_ICONS/drawable-xhdpi/ic_launcher.png
convert $ICON_NAME -resize 96x96 $DIR_TO_SAVE_ICONS/drawable-xhdpi/ic_launcher_round.png
convert $ICON_NAME -resize 72x72 $DIR_TO_SAVE_ICONS/drawable-hdpi/ic_launcher.png
convert $ICON_NAME -resize 72x72 $DIR_TO_SAVE_ICONS/drawable-hdpi/ic_launcher_round.png
convert $ICON_NAME -resize 48x48 $DIR_TO_SAVE_ICONS/drawable-mdpi/ic_launcher.png
convert $ICON_NAME -resize 48x48 $DIR_TO_SAVE_ICONS/drawable-mdpi/ic_launcher_round.png
convert $ICON_NAME -resize 36x36 $DIR_TO_SAVE_ICONS/drawable-ldpi/ic_launcher.png
convert $ICON_NAME -resize 36x36 $DIR_TO_SAVE_ICONS/drawable-ldpi/ic_launcher_round.png

#create a zip to copy to android app, res folder

cd $DIR_TO_SAVE_ICONS
zip -r $ICON_NAME.zip .

echo "Icon zip $ICON_NAME.zip is ready at $DIR_TO_SAVE_ICONS"
