"""
Utility functions for handling images.
"""
import cv2 as cv
import numpy as np


def crop_img_array(image, height_dim, width_dim, vert_shift=0, horiz_shift=0):
    """
    Pads an image (numpy array) if needed, and then crops the center of
    the image to size (height_dim, width_dim).

    vert_shift and horiz_shift can be specified if the center of the
    cropped image should be shifted from the center. The image is still
    only padded as much as would be needed for center cropping; the
    shifted crop is performed within the padded image.

    Parameters
    ----------
    image: numpy.ndarray
        Numpy array containing the image.
        Takes arrays with or without a channel dimension
    height_dim: int
        The desired height of the image after cropping
    width_dim: int
        The desired width of the image after cropping
    vert_shift: int, optional
    horiz_shift: int, optional
    """

    orig_height, orig_width, *channels = image.shape
    vertpad_1 = vertpad_2 = horizpad_1 = horizpad_2 = 0

    if orig_height < height_dim:
        vertpad_1, vertpad_2 = _find_padding(orig_height, height_dim)
    if orig_width < width_dim:
        horizpad_1, horizpad_2 = _find_padding(orig_width, width_dim)

    if len(channels) > 0:
        image_padded = np.pad(image,
                              pad_width=((vertpad_1, vertpad_2),
                                         (horizpad_1, horizpad_2),
                                         (0, 0)))
    else:
        image_padded = np.pad(image, pad_width=((vertpad_1, vertpad_2),
                                                (horizpad_1, horizpad_2)))

    start_vert = _find_shift(image_padded.shape[0], height_dim, vert_shift)
    start_horiz = _find_shift(image_padded.shape[1], width_dim, horiz_shift)

    if len(channels) > 0:
        return image_padded[start_vert:(start_vert + height_dim),
                            start_horiz:(start_horiz + width_dim),
                            :]
    else:
        return image_padded[start_vert:(start_vert + height_dim),
                            start_horiz:(start_horiz + width_dim)]


def scale_img(image, scale_factor):
    """
    Scales image in a 2D array by scale_factor

    Parameters
    ----------
    image: numpy.ndarray
        2D numpy array containing the image.
    scale_factor: int or float
        How much image should be scaled by. Should be greater than 0.
        For example, 1 keeps the image the same, and 2 doubles the
        height and width
    """

    width = int(image.shape[1] * scale_factor)
    height = int(image.shape[0] * scale_factor)
    dim = (width, height)

    if scale_factor > 1:
        scaled_img = cv.resize(image, dim, interpolation=cv.INTER_LINEAR)
    else:
        scaled_img = cv.resize(image, dim, interpolation=cv.INTER_AREA)

    return scaled_img


def _find_padding(raw_dim, padded_dim):
    """
    Determines the padding for each side to increase a dimension from
    from raw_dim to padded_dim.

    Example:
    heightpad_1, heightpad_2 = find_padding(orig_height, output_height)
    """

    totalpad = padded_dim - raw_dim
    if totalpad % 2 == 0:
        pad_1 = int(totalpad / 2)
        pad_2 = int(totalpad / 2)
    else:
        pad_1 = int(totalpad / 2 + 0.5)
        pad_2 = int(totalpad // 2)

    return pad_1, pad_2


def _find_shift(start_dim, end_dim, requested_shift):
    """
    Used in crop_image_array function - performs the specified shift in
    a dimension as much as possible such that the cropped image does not
    go beyond the dimensions of the input image.
    """

    max_shift = (start_dim - end_dim) // 2
    if max_shift < abs(requested_shift):
        startpoint = int(start_dim // 2 - (end_dim / 2) + (max_shift * np.sign(requested_shift)))
    else:
        startpoint = int(start_dim // 2 - (end_dim / 2) + requested_shift)

    return startpoint
