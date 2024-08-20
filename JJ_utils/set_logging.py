"""
Has one function, set_logging, which sets up logging configurations.
"""

import importlib.resources
import json
import logging
import logging.config
import os


def set_logging(log_dir, log_filename, logging_config='logging_config.json',
                stream_level_debug=None, stream_level_info=None):
    """
    Returns a logger using logging configurations provided by a
    dictConfig json file.

    The json file must be in jj_utils/docs and have a file handler
    named 'file_handler'.

    This module should be run in the parent script, and child scripts
    (i.e. modules) can have:
        import logging
        logger = logging.getLogger(__name__)

    Parameters
    ----------
    log_dir : str
        Directory where the log will be written
    log_filename : str
        Filename of the log
    logging_config : str, optional
        Filename of the config json file within jj_utils/docs
        (default is 'logging_config.json')
    stream_level_debug : bool, optional
        If a StreamHandler handler is defined in the config file (which
        is the case in the default config file), changes the threshold
        level of the handler to DEBUG (default is None)
    stream_level_info : bool, optional
        If a StreamHandler handler is defined in the config file,
        changes the threshold level of the handler to INFO
        (default is None)
    """

    with importlib.resources.open_text('jj_utils.docs', logging_config) as f:
        log_config = json.load(f)

    log_config['handlers']['file_handler']['filename'] = os.path.join(log_dir, log_filename)

    logging.config.dictConfig(log_config)

    logger = logging.getLogger()

    # [added 'is True' because shouldn't run if, i.e. 0 is passed; better to use type hints?]
    if stream_level_debug is True:
        for handler in (h for h in logger.handlers if isinstance(h, logging.StreamHandler)):
            handler.setLevel(logging.DEBUG)

    if stream_level_info is True:
        for handler in (h for h in logger.handlers if isinstance(h, logging.StreamHandler)):
            handler.setLevel(logging.INFO)

    return logger


