#!/usr/bin/env python3

"""
Creates new dataset for MVP segmentation model training.
"""

import argparse
import datetime
import itertools
import json
import logging
import os
from pathlib import Path
import random
import sys

import cv2 as cv
import lz4.frame
import numpy as np

from jj_utils import array_utils, img_utils, set_logging
from config import DEBUG, MODEL_TYPE, VIDEO_ARRAY_DIR, LABEL_DIR, DATASET_DIR, TRAIN_DIM
from config import AUG_FOLD, BLANK_AUG_FOLD, BLANK_TRAINING_FOLD, NUM_VAL_FILES, NUM_TEST_FILES
from config import LOG_DIR, LOG_NAME

logger = logging.getLogger(__name__)


def create_main_dataset():
    manifest_lines = []

    for job in LABEL_DIR.iterdir():
        for output_manifest in (job / 'manifests' / 'output').iterdir():
            with open(output_manifest) as f:
                for line in f:
                    manifest_lines.append(json.loads(line))

    # takes out unlabeled entries
    manifest_lines = [line for line in manifest_lines if 'mv-label-ref' in line]

    dataset = []

    for manifest_line in manifest_lines:
        mv_label_path = Path(manifest_line['mv-label-ref'])
        path_index = mv_label_path.parts.index('bwh')
        mv_label_path_local = LABEL_DIR.joinpath(*mv_label_path.parts[(path_index + 1):])

        with open(mv_label_path_local, 'r') as f:
            mv_label = json.load(f)

        manifest_line['annotations'] = mv_label['detection-annotations']

        for annotation in manifest_line['annotations']:
            annotation['coords'] = {}
            for polygon in annotation['polygons']:
                polygon_class_id = polygon['class-id']
                polygon_coords = []
                for point in polygon['vertices']:
                    polygon_coords.append((point['x'], point['y']))
                annotation['coords'][polygon_class_id] = np.array(polygon_coords).reshape((-1, 1, 2))

        source_path = Path(manifest_line['source-ref'])
        source_path_local = VIDEO_ARRAY_DIR / source_path.parts[5][6:-4]

        try:
            fp = lz4.frame.open(source_path_local, mode='rb')
            video = np.load(fp)
            fp.close()
        except:
            #logger.debug('Video could not be loaded', exc_info=True)
            continue

        for annotation in manifest_line['annotations']:
            if MODEL_TYPE == 'single':
                img = video[int(annotation['frame-no'])]
            elif MODEL_TYPE == 'multi':
                stack = []
                for i in range(-2, 3):
                    try:
                        frame_img = video[int(annotation['frame-no']) + i]
                    except:
                        if i == 0:
                            raise ValueError('Video frame')
                        frame_img = np.zeros(video[i].shape)
                    stack.append(frame_img)
                img = np.stack(stack)

            try:
                coord_0 = annotation['coords']['0']
                coord_0_array = np.zeros((img.shape[1], img.shape[2], 1), np.uint8)
                cv.fillPoly(coord_0_array, [coord_0], 255)

                coord_1 = annotation['coords']['1']
                coord_1_array = np.zeros((img.shape[1], img.shape[2], 1), np.uint8)
                cv.fillPoly(coord_1_array, [coord_1], 255)
            except:
                #logger.debug('Coord_0 and coord_1 could not be obtained for annotation', exc_info=True)
                pass

            dataset.append({'frame': img, 'coord_0': coord_0_array, 'coord_1': coord_1_array,
                            'file': manifest_line['source-ref']})

    logger.debug(f'Length of dataset: {len(dataset)}')
    logger.debug(f'Sample frame in dataset: {array_utils.array_info(dataset[0]["frame"])}')

    if DEBUG:
        dataset = dataset[:60]

    return dataset


def split_train_val_test(dataset):
    grouped = itertools.groupby(dataset, lambda x: x['file'])

    file_names = []
    for key, _ in grouped:
        file_names.append(key)
    random.shuffle(file_names)

    test_keys = file_names[:NUM_TEST_FILES]
    val_keys = file_names[NUM_TEST_FILES:(NUM_TEST_FILES + NUM_VAL_FILES)]
    train_keys = file_names[(NUM_TEST_FILES + NUM_VAL_FILES):]

    if DEBUG:
        third = len(file_names)//3
        test_keys = file_names[:third]
        val_keys = file_names[third : third*2]
        train_keys = file_names[third*2:]

    dataset_train = []
    dataset_val = []
    dataset_test = []

    for sample in dataset:
        if sample['file'] in train_keys:
            dataset_train.append(sample)
        elif sample['file'] in val_keys:
            dataset_val.append(sample)
        elif sample['file'] in test_keys:
            dataset_test.append(sample)

    logger.debug(f'Number of samples in dataset_train: {len(dataset_train)}')

    return dataset_train, dataset_val, dataset_test


class AugmentFrame:
    """
    Creates an altered version of frame or frame stack along with its
    corresponding coord_0 and coord_1
    """

    def __init__(self, frame, coord_0, coord_1, seed=None):
        self.frame = frame
        self.coord_0 = coord_0
        self.coord_1 = coord_1
        self.train_dim = TRAIN_DIM
        self.seed = seed

        if self.seed:
            random.seed(seed)

        for i in range(20):   # tries random augmentation several times if part of both leaflets is not included
            if self.train_dim == 224:
                self.scale_factor = random.random() / 2 + 0.7
            elif self.train_dim == 448:
                self.scale_factor = random.random() / 3 + 0.3
            else:
                raise ValueError(f'Please define scale_factor for train_dim {self.train_dim}.')

            self.vert_shift = random.randint(10, 80)
            self.horiz_shift = random.randint(10, 80)
            self.rotate_angle = random.randint(-30, 30)
            self.brightness = random.randint(-30, 40)
            self.contrast = random.random() * 1.3 + 0.7

            self.coord_0 = self.transform_image(self.coord_0, change_brightness_contrast=False)
            self.coord_1 = self.transform_image(self.coord_1, change_brightness_contrast=False)

            if (self.coord_0.sum() > (25 * 255)) and (self.coord_1.sum() > (25 * 255)):
                self.coord_0 = self.coord_0.astype(bool)
                self.coord_1 = self.coord_1.astype(bool)
            else:
                continue

            if len(np.squeeze(self.frame).shape) == 2:
                self.frame = self.transform_image(self.frame)
            elif len(np.squeeze(self.frame).shape) == 3:
                frame_stack = []
                for single_frame in self.frame:
                    single_frame = self.transform_image(single_frame)
                    frame_stack.append(single_frame)

                self.frame = np.stack(frame_stack)
            else:
                raise ValueError(f'Invalid shape for frame ({self.frame.shape})')
            break
        else:
            self.frame = None

    def transform_image(self, image, change_brightness_contrast=True):
        image = self.rotate(image)
        image = img_utils.scale_img(image, self.scale_factor)
        image = img_utils.crop_img_array(image, self.train_dim, self.train_dim, self.vert_shift,
                                         self.horiz_shift)
        if change_brightness_contrast:
            image = self.adjust_brightness(image)
            image = self.adjust_contrast(image)

        return image

    def rotate(self, image):
        """Rotates image array

        [ ] Maybe modify to make full image visible - https://www.pyimagesearch.com/2017/01/02/rotate-images-correctly-with-opencv-and-python/
        """

        image_center = tuple(np.array(image.shape[1::-1]) / 2)
        rot_mat = cv.getRotationMatrix2D(image_center, self.rotate_angle, 1.0)
        result = cv.warpAffine(image, rot_mat, image.shape[1::-1], flags=cv.INTER_LINEAR)

        return result.reshape(result.shape[0], result.shape[1], 1)

    def adjust_brightness(self, image):
        """Adds 'brightness' value to each pixel in array ('brightness' can be negative)"""

        result = np.where((image + self.brightness) > 255, 255, image + self.brightness)
        result = np.where(result < 0, 0, result)

        return result

    def adjust_contrast(self, image):
        """Adjusts contrast of array (less contrast if 'value'<1,  more contrast if 'value'>1)"""

        result = np.where((image * self.contrast) > 255, 255, image * self.contrast)
        result = np.where(result < 0, 0, result)

        return result


def prep_data(data):
    coord_0 = data['coord_0']
    coord_1 = data['coord_1']

    if TRAIN_DIM == 224:
        coord_0 = img_utils.scale_img(coord_0, 0.5)
        coord_1 = img_utils.scale_img(coord_1, 0.5)
    coord_0 = img_utils.crop_img_array(coord_0, TRAIN_DIM, TRAIN_DIM).astype(bool)
    coord_1 = img_utils.crop_img_array(coord_1, TRAIN_DIM, TRAIN_DIM).astype(bool)

    coord = coord_0 | coord_1

    if MODEL_TYPE == 'single':
        frame = img_utils.crop_img_array(data['frame'], TRAIN_DIM, TRAIN_DIM)

    elif MODEL_TYPE == 'multi':
        frames_resized = []
        for single_frame in data['frame']:
            if TRAIN_DIM == 224:
                single_frame = img_utils.scale_img(single_frame, 0.5)
            single_frame_resized = img_utils.crop_img_array(single_frame, TRAIN_DIM, TRAIN_DIM)
            frames_resized.append(single_frame_resized)
        frame = np.stack(frames_resized) / 255

    return frame, coord_0, coord_1, coord


def replace_with_blank_frames(framestack):
    frame_shape = framestack[2].shape
    start_or_end = random.randint(0, 1)
    one_or_two_blank = random.randint(1, 2)

    if start_or_end == 0:
        framestack[0] = np.zeros(frame_shape)
        if one_or_two_blank == 2:
            framestack[1] = np.zeros(frame_shape)
    elif start_or_end == 1:
        framestack[4] = np.zeros(frame_shape)
        if one_or_two_blank == 2:
            framestack[3] = np.zeros(frame_shape)

    return framestack


def augment_dataset(dataset_train):
    aug_dataset = []

    for data in dataset_train:
        for i in range(AUG_FOLD):     # creates multiple augmented samples for each original sample

            augmented = AugmentFrame(data['frame'], data['coord_0'], data['coord_1'])

            if augmented.frame is not None:
                if i < BLANK_AUG_FOLD and MODEL_TYPE == 'multi':
                    augmented.frame = replace_with_blank_frames(augmented.frame)

                aug_dataset.append({'frame': augmented.frame / 255,
                                    'coord_0': augmented.coord_0,
                                    'coord_1': augmented.coord_1,
                                    'coord': augmented.coord_0 | augmented.coord_1
                                    })

    return aug_dataset


def add_blank_samples(dataset_train):
    add_blank_samples_dataset = []

    for i in range(BLANK_TRAINING_FOLD):
        for data in dataset_train:
            new_frame = replace_with_blank_frames(data['frame'])
            add_blank_samples_dataset.append({'frame': new_frame,
                                              'coord_0': data['coord_0'],
                                              'coord_1': data['coord_1'],
                                              'coord': data['coord']
                                              })

    return add_blank_samples_dataset


def make_x_y_arrays(dataset):
    X_list = []
    #y_0_list = []
    #y_1_list = []
    y_list = []

    logger.debug(f'Samples in dataset for make_x_y_arrays: {len(dataset)}')

    for data in dataset:
        X_list.append(np.expand_dims(data['frame'], axis=-1))
        #y_0_list.append(np.expand_dims(data['coord_0'], axis=-1))
        #y_1_list.append(np.expand_dims(data['coord_1'], axis=-1))
        y_list.append(np.expand_dims(data['coord'], axis=-1))

    X_array = np.stack(X_list, axis=0).astype(np.float32)
    y_array = np.stack(y_list, axis=0)

    return X_array, y_array


def make_datasets(filename):

    logger.info(f'\n\nStarting preprocessing\n{datetime.datetime.now().strftime("%m/%d/%Y %H:%M")}')

    dataset = create_main_dataset()
    dataset_train, dataset_val, dataset_test = split_train_val_test(dataset)
    aug_dataset = augment_dataset(dataset_train)

    for data in dataset_train:
        data['frame'], data['coord_0'], data['coord_1'], data['coord'] = prep_data(data)

    for data in dataset_val:
        data['frame'], data['coord_0'], data['coord_1'], data['coord'] = prep_data(data)

    for data in dataset_test:
        data['frame'], data['coord_0'], data['coord_1'], data['coord'] = prep_data(data)

    if BLANK_TRAINING_FOLD > 0:
        add_blank_samples_dataset = add_blank_samples(dataset_train)
        dataset_train = dataset_train + aug_dataset + add_blank_samples_dataset
    else:
        dataset_train = dataset_train + aug_dataset

    X_train, y_train = make_x_y_arrays(dataset_train)
    X_val, y_val = make_x_y_arrays(dataset_val)
    X_test, y_test = make_x_y_arrays(dataset_test)

    filepath = os.path.join(DATASET_DIR, filename)

    np.save(filepath + '_X_train.npy', X_train)
    np.save(filepath + '_y_train.npy', y_train)
    np.save(filepath + '_X_val.npy', X_val)
    np.save(filepath + '_y_val.npy', y_val)
    np.save(filepath + '_X_test.npy', X_test)
    np.save(filepath + '_y_test.npy', y_test)

    return X_train, y_train, X_val, y_val, X_test, y_test


if __name__ == '__main__':

    logger = set_logging(LOG_DIR, LOG_NAME, stream_level_debug=DEBUG)

    if DEBUG:
        logger.warning('Running in debug mode')

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-n' '--new_filename', type=str,
                        help='filename base of dataset that will be created', metavar='')

    if len(sys.argv) == 1:            # prints help message if no arguments given
        parser.print_help(sys.stderr)
        sys.exit(1)
    args, _ = parser.parse_known_args()

    datasets = make_datasets(args.new_filename)
