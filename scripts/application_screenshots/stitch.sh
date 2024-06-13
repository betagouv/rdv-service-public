cd $1

# Step 0: Optimize all images to reduce file size using pngquant
for dir in */; do
    pngquant --ext .png --force "$dir"*.png
done

# Step 1: Create intermediate stitched images for each subfolder
for dir in */; do
    convert \( "$dir"*.png -splice 100x0 \) +append "${dir%/}.png";
done

pngquant --ext .png --force *.png

# Step 2: Stitch all intermediate images vertically into a single image
convert *.png -splice 0x100 -append final_stitched.png

pngquant --ext .png --force final_stitched.png
