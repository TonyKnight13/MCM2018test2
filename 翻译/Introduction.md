## background
With the rapid development of artificial intelligence, there are more and more applications of images, such as face recognition and automatic recognition. There are two things that cannot be ignored before using images for related tasks.The first is image compression, in order to reduce the redundant information in image data and to store and transmit data in a more efficient format; the second is image restoration, which USES certain techniques to reproduce the missing information in the image.  These two technologies have laid a foundation for the rapid development of relevant image application technologies. In this context, we want to be able to build a process model to implement these two technologies.

## our work
1. The image compression we need to do is lossy compression.
2. How to make image compression model suitable for general situation?
3. What is the relationship between the models we want to build?
4. Does the missing data proportion have special meaning?
5. What is the measure of restoration?
6. All missing pixel values for a given image are non-zero.
7. How to deal with the static background of video?

# Assumptions
1. We are dealing with bitmaps rather than vectors.
2. Assume that the missing types of information in question 3 are the same as those in the case diagram.
3. Assume that the image the image compression algorithm to process is not too extreme for the its size, that is, the image size is not too small or too large.
4. Assume the image compression algorithm is aimed at the image of RGB color.
5. Assume that the image compression requires not to lose too much information, not considering the high compression of the signal loss.