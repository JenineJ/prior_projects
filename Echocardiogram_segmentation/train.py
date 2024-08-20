#!/usr/bin/env python3

"""
Trains MVP segmentation model. Uses existing dataset or creates a new one
"""

import argparse
import datetime
import logging
import os
import sys

import cv2 as cv
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from jj_utils import time_script
from jj_utils.set_logging import set_logging
from jj_utils import pytorch_utils

from config import DEBUG, TRAIN_DIM, LOG_DIR, LOG_NAME, DATASET_DIR, MODEL_DIR
from config import BATCH_SIZE, N_EPOCHS, PATIENCE, LEARNING_RATE, WEIGHT_DECAY
from mvp import preprocess, unet_model

logger = logging.getLogger(__name__)


def get_rect_pred(preds_array):
    # For each image in preds_array, gets the rectangle that encompasses
    # the largest contiguous area in the image

    rect_imgs = []
    rect_points = []

    for pred in preds_array:
        img = np.array(pred * 255, dtype=np.uint8)
        output = cv.connectedComponentsWithStats(img, 8, cv.CV_32S)
        (num_regions, regions, stats, centroids) = output

        max_area = 0
        for i in range(1, num_regions):
            if stats[i, cv.CC_STAT_AREA] > max_area:
                max_area = stats[i, cv.CC_STAT_AREA]
                max_area_i = i

        x = stats[max_area_i, cv.CC_STAT_LEFT]
        y = stats[max_area_i, cv.CC_STAT_TOP]
        w = stats[max_area_i, cv.CC_STAT_WIDTH]
        h = stats[max_area_i, cv.CC_STAT_HEIGHT]

        rect_img = np.zeros(img.shape, dtype=np.int8)
        cv.rectangle(rect_img, (x, y), (x + w, y + h), 1, 2)

        rect_imgs.append(rect_img)
        rect_points.append((x, y, x + w, y + h))

    return (np.stack(rect_imgs), np.stack(rect_points))


def dice_coef(y_true, y_pred):       # dice coefficient using numpy arrays
    y_true_f = y_true.flatten()         # [ ] remove later and use tensors instead?
    y_pred_f = y_pred.flatten()
    union = np.sum(y_true_f) + np.sum(y_pred_f)
    if union == 0:
        return 1
    intersection = np.sum(y_true_f * y_pred_f)
    return 2. * intersection / union


def main(existing_filename, new_filename):

    if DEBUG:
        logger.warning('Running in debug mode')

    if new_filename:
        X_train, y_train, X_val, y_val, X_test, y_test = preprocess.make_datasets(new_filename)
        logger.info(f'Created datasets with filename base {new_filename}')
        filename_base = new_filename

    else:
        filepath = os.path.join(DATASET_DIR, existing_filename)

        X_train = np.load(filepath + '_X_train.npy')
        y_train = np.load(filepath + '_y_train.npy')
        X_val = np.load(filepath + '_X_val.npy')
        y_val = np.load(filepath + '_y_val.npy')
        X_test = np.load(filepath + '_X_test.npy')
        y_test = np.load(filepath + '_y_test.npy')

        logger.info(f'Loaded datasets with filename base {existing_filename}')
        filename_base = existing_filename


    X_train = pytorch_utils.convert_npy_torch(X_train)
    X_val = pytorch_utils.convert_npy_torch(X_val)
    X_test = pytorch_utils.convert_npy_torch(X_test)

    y_train = pytorch_utils.convert_npy_torch(y_train)
    y_val = pytorch_utils.convert_npy_torch(y_val)
    y_test = pytorch_utils.convert_npy_torch(y_test)

    training_data = pytorch_utils.DatasetFromTensor(X_train, y_train)
    validation_data = pytorch_utils.DatasetFromTensor(X_val, y_val)

    train_loader = DataLoader(training_data, batch_size=BATCH_SIZE, shuffle=True)
    val_loader = DataLoader(validation_data, batch_size=BATCH_SIZE, shuffle=True)


    model = unet_model.UNetWrapper(in_channels=1)
    device = torch.device('cuda:0')

    if torch.cuda.device_count() > 1:
        logger.info(f'Using {torch.cuda.device_count()} GPUs')
    model = nn.DataParallel(model)

    model.to(device)
    model.cuda(device=device)

    optimizer = torch.optim.AdamW(model.parameters(), lr = LEARNING_RATE, weight_decay=WEIGHT_DECAY)
    criterion = nn.BCELoss()

    model_dict_path = os.path.join(
        MODEL_DIR,
        f'{datetime.datetime.now().strftime("%Y_%m_%d-%H_%M")}_model_state.pt'
    )


    pytorch_utils.training_loop(model, device, train_loader, val_loader, N_EPOCHS, PATIENCE,
                                optimizer, criterion, model_dict_path)


    preds_filename = filename_base + f'_test_preds_{datetime.datetime.now().strftime("%Y_%m_%d-%H_%M")}'
    test_preds = pytorch_utils.forward_pass(model, device, X_test, optimizer, model_dict_path,
                                            DATASET_DIR, preds_filename)

    dice_fn = pytorch_utils.DiceLoss()
    dice = 1 - dice_fn(test_preds, y_test)
    print(f'Dice on test set is: {dice.mean():.3f}')       # [ ] send to stdout and log

    preds_thresholded = np.where(test_preds > 0.3, 1, test_preds)
    preds_thresholded = np.where(preds_thresholded < 1, 0, preds_thresholded)
    y_test = y_test.numpy()
    dice = []
    for test_sample, pred_sample in zip(y_test, preds_thresholded):
        dice.append(dice_coef(test_sample, pred_sample))
    print(f'Dice on test set after threshold of 0.3 is: {np.mean(dice):.3f}')

    np.save(os.path.join(DATASET_DIR, preds_filename + '_thresholded'), preds_thresholded)


if __name__ == '__main__':

    logger = set_logging(LOG_DIR, LOG_NAME, stream_level_debug=DEBUG)

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-e', '--existing_filename', type=str,
                        help='filename base for the datasets to be used', metavar='')
    parser.add_argument('-n', '--new_filename', type=str,
                        help='first creates datasets using this as the filename base', metavar='')

    if len(sys.argv) == 1:            # prints help message if no arguments given
        parser.print_help(sys.stderr)
        sys.exit(1)
    args, _ = parser.parse_known_args()

    main(args.existing_filename, args.new_filename)
