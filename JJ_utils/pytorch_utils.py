"""
Utility functions for use with PyTorch
"""

import logging
import os

import numpy as np
import torch
from torch.utils.data.dataset import Dataset
import torchvision

logger = logging.getLogger(__name__)


def convert_npy_torch(arr):
    """
    Converts a channels-last image Numpy array to Torch tensor of dtype
    torch.float32 and uses the final dimension as the channel dimension.

    If the array has greater than 3 dimensions, the channel becomes the
    second dimension of the array.

    Parameters
    ----------
    arr: numpy.ndarray
        Channels-last Numpy array containing images; can have 3 to 5
        dimensions
    """

    tensor_from_arr = torch.from_numpy(arr)
    if tensor_from_arr.dtype != torch.float32:
        tensor_from_arr = tensor_from_arr.to(torch.float32)

    if len(tensor_from_arr.shape) == 3:
        tensor_from_arr = tensor_from_arr.movedim(-1, 0)
    if len(tensor_from_arr.shape) > 3:
        tensor_from_arr = tensor_from_arr.movedim(-1, 1)

    return tensor_from_arr


class DatasetFromTensor(Dataset):
    """
    Creates a PyTorch Dataset from an X tensor and corresponding
    y tensor, where the first dimension of each tensor represents the
    samples.

    Parameters
    ----------
    arr: numpy.ndarray
        Channels-last Numpy array containing images; can have 3 to 5
        dimensions
    """

    def __init__(self, X_tensor, y_tensor):
        self.X_tensor = X_tensor
        self.y_tensor = y_tensor

    def __len__(self):
        return self.X_tensor.shape[0]

    def __getitem__(self, idx):
        X = self.X_tensor[idx]
        y = self.y_tensor[idx]
        return X, y


class DiceLoss():
    """
    Callable class that calculates the dice loss (1 - dice coefficient).

    Parameters
    ----------
    epsilon: integer, optional
        Epsilon for the dice coefficient calculation; default 1
    prediction: tensor
        The prediction tensor; used when calling the class instance.
    label: tensor
        The ground truth label tensor; used when calling the class
        instance
    """

    def __init__(self, epsilon=1):
        self.epsilon = epsilon

    def __call__(self, prediction, label):
        diceLabel = label.sum(dim=[1, 2, 3])
        dicePrediction = prediction.sum(dim=[1, 2, 3])
        diceCorrect = (prediction * label).sum(dim=[1, 2, 3])

        diceRatio = (2 * diceCorrect + self.epsilon) \
            / (dicePrediction + diceLabel + self.epsilon)

        return 1 - diceRatio


def training_loop(model, device, train_loader, val_loader, epochs, patience, optimizer, criterion,
                  model_dict_path, tensorboard_out = None):
    # [ ] turn into class?

    train_losses, valid_losses = [], []
    min_val_loss = 10000

    for t in range(1, epochs + 1):
        try:
            # training
            t_losses = []
            model.train(True)
            for i, data in enumerate(train_loader):
                src, tgt = data
                src, tgt = src.to(device), tgt.to(device)
                optimizer.zero_grad()
                out = model(src)
                loss = criterion(out, tgt).mean()
                t_losses.append(loss.item())
                loss.backward()
                optimizer.step()
                if i % 100 and tensorboard_out:
                    img_grid = torchvision.utils.make_grid([src[0][0][0].unsqueeze(0), tgt[0][0].unsqueeze(0), out[0][0].unsqueeze(0)])
                    tensorboard_out.add_image('source_target_predicted_training', img_grid, t * len(train_loader) + i)
            train_losses.append(t_losses)
            if tensorboard_out:
                tensorboard_out.add_scalar('training_loss',
                            np.mean(train_losses),
                            t)

            # validation
            v_losses = []
            model.train(False)
            with torch.set_grad_enabled(False):
                for i, data in enumerate(val_loader):
                    src, tgt = data
                    src, tgt = src.to(device), tgt.to(device)
                    out = model(src)
                    loss = criterion(out, tgt).mean()
                    v_losses.append(loss.item())
                    
                    i += 1
                    if i % 100 and tensorboard_out:
                        img_grid = torchvision.utils.make_grid([src[0][0][0].unsqueeze(0), tgt[0][0].unsqueeze(0), out[0][0].unsqueeze(0)])
                        tensorboard_out.add_image('source_target_predicted_validation', img_grid, t * len(val_loader) + i)
                valid_losses.append(v_losses)
                val_loss = np.mean(v_losses)
            if tensorboard_out:
                tensorboard_out.add_scalar('validation_loss', val_loss, t)

            if not np.all(np.isfinite(t_losses)):
                raise RuntimeError('NaN or Inf in training loss, cannot recover. Exiting.')
            log = f'Epoch: {t} - Training Loss: {np.mean(t_losses):.2e}, Validation Loss: {val_loss:.2e}'

            print(log)

            if val_loss < min_val_loss:
                epochs_no_improve = 0
                min_val_loss = val_loss
                torch.save({
                    'model_state_dict': model.state_dict(),
                    'optimizer_state_dict': optimizer.state_dict(),
                }, model_dict_path)
            else:
                epochs_no_improve += 1

            if t > 10 and epochs_no_improve == patience:
                print('Early stopping')
                break

        except KeyboardInterrupt:
            break

def classification_training_loop(model, device, train_loader, val_loader, epochs, patience, optimizer, criterion,
                  model_dict_path, tensorboard_out = None):
    # [ ] turn into class?

    train_losses, valid_losses = [], []
    min_val_loss = 10000

    for t in range(1, epochs + 1):
        try:
            # training
            t_losses = []
            model.train(True)
            for i, data in enumerate(train_loader):
                src, tgt = data
                src, tgt = src.to(device), tgt.to(device)
                optimizer.zero_grad()
                out = model(src)
                loss = criterion(out, tgt).mean()
                t_losses.append(loss.item())
                loss.backward()
                optimizer.step()
                if i % 100 and tensorboard_out:
                    img_grid = torchvision.utils.make_grid([src[0][0][0].unsqueeze(0), tgt[0][0].unsqueeze(0), out[0][0].unsqueeze(0)])
                    tensorboard_out.add_image('source_target_predicted_training', img_grid, t * len(train_loader) + i)
            train_losses.append(t_losses)
            if tensorboard_out:
                tensorboard_out.add_scalar('training_loss',
                            np.mean(train_losses),
                            t)

            # validation
            v_losses = []
            model.train(False)
            with torch.set_grad_enabled(False):
                for i, data in enumerate(val_loader):
                    src, tgt = data
                    src, tgt = src.to(device), tgt.to(device)
                    out = model(src)
                    loss = criterion(out, tgt).mean()
                    v_losses.append(loss.item())
                    
                    i += 1
                    if i % 100 and tensorboard_out:
                        img_grid = torchvision.utils.make_grid([src[0][0][0].unsqueeze(0), tgt[0][0].unsqueeze(0), out[0][0].unsqueeze(0)])
                        tensorboard_out.add_image('source_target_predicted_validation', img_grid, t * len(val_loader) + i)
                valid_losses.append(v_losses)
                val_loss = np.mean(v_losses)
            if tensorboard_out:
                tensorboard_out.add_scalar('validation_loss', val_loss, t)

            if not np.all(np.isfinite(t_losses)):
                raise RuntimeError('NaN or Inf in training loss, cannot recover. Exiting.')
            log = f'Epoch: {t} - Training Loss: {np.mean(t_losses):.2e}, Validation Loss: {val_loss:.2e}'

            print(log)

            if val_loss < min_val_loss:
                epochs_no_improve = 0
                min_val_loss = val_loss
                torch.save({
                    'model_state_dict': model.state_dict(),
                    'optimizer_state_dict': optimizer.state_dict(),
                }, model_dict_path)
            else:
                epochs_no_improve += 1

            if t > 10 and epochs_no_improve == patience:
                print('Early stopping')
                break

        except KeyboardInterrupt:
            break

def forward_pass(model, device, X_data, optimizer, model_dict_path, output_path, output_filename):
    # [ ] check

    checkpoint = torch.load(model_dict_path)
    model.load_state_dict(checkpoint['model_state_dict'])
    optimizer.load_state_dict(checkpoint['optimizer_state_dict'])

    model.eval()

    with torch.no_grad():
        preds = model(X_data)
        preds = preds.to(device).cpu()

    output_dest = os.path.join(output_path, output_filename)
    np.save(os.path.join(output_path, output_filename), preds)

    print(f'Predictions saved to {output_dest}.')   # [ ] send to stdout and log

    return preds
