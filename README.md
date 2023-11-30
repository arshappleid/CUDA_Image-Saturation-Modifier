
## Description
A Simple Saturation Adjustor that , takes in a saturation factory float number. Then loops through each pixel of an image , adjust the saturation faction in the HSV codec. Then save the new image as outputImage.

This makes use of multi Threaded performance , and CUDA cores to perform the manipulation of pixels efficiently.

### Install the Libraries Using
In an Ubuntu Environment , make sure CUDA env is installed.
```
sudo apt-get update
sudo apt-get install libopencv-dev
```
### File Description
1. main.cu - Modify fileName , and Saturation factor here
2. saturation.cu - Has all the code to perform the saturation.


### Run the Code Using
``` 
nvcc saturation.cu main.cu -o main $(pkg-config --cflags --libs opencv); ./main
```

### Sample Image Run 

#### Initial Image
<img src = "./farmImg.webp" style = "zoom:50%;">

#### Output Image
<img src = "./outputImage.webp" style = "zoom:50%;">