"""
Utility functions for handling numpy arrays
"""


def array_info(arr):
    """Returns a string with information about the array"""

    return (
        'Array info:\n'
        f'Shape is {arr.shape}\n'
        f'Dtype is {arr.dtype}\n'
        f'Min is {arr.min()}\n'
        f'Max is {arr.max()}'
    )
