"""
Configs for scripts in MVP repo
"""

from pathlib import Path


DEBUG = False               # uses only a subset of the data, and logs debug messages

MODEL_TYPE = 'multi'        # if 'multi', model uses labeled frame and surrounding frames
                                # if 'single', model only uses labeled frame

TRAIN_DIM = 224             # size of images that will be used- 224 or 448

LOG_DIR = Path('/mnt/obi0/jjohn2/projects/mvp_data/logs')
LOG_NAME = 'log'            # name of log file to be created/appended to

DATASET_DIR = Path('/mnt/obi0/jjohn2/projects/mvp_data/datasets')
MODEL_DIR = Path('/mnt/obi0/jjohn2/projects/mvp_data/models')


# Preprocessing
VIDEO_ARRAY_DIR = Path('/mnt/obi0/sgoto/MVP/segmentation/BWH/batch0/collectNPY/npyFiles')
LABEL_DIR = Path('/mnt/obi0/jjohn2/projects/mvp_data/labels')

NUM_VAL_FILES = 14          # number of files to include in validation set (if 5 labeled frames per
                                # file, there will be NUM_VAL_FILES*5 samples in the val set
NUM_TEST_FILES = 17         # number of files to include in the test set (if 5 labeled frames per
                                # file, there will be NUM_TEST_FILES*5 samples in the test set

AUG_FOLD = 2                # each training sample will have AUG_FOLD corresponding augmented samples

# only applicable if MODEL_TYPE is 'multi
BLANK_AUG_FOLD = 1          # of the augmented samples for each training sample, BLANK_AUG_FOLD
                                # will have some blank frames
BLANK_TRAINING_FOLD = 1     # each training sample will have BLANK_TRAINING_FOLD corresponding
                                # samples,which are the same as the original but with some
                                # blank frames


# Model training
BATCH_SIZE = 8
N_EPOCHS = 100
PATIENCE = 101

LEARNING_RATE = 1e-4
WEIGHT_DECAY = 1e-6
