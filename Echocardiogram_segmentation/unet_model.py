# UNet model (currently for 5-frame model and 224*224 images)
# modified from https://github.com/jvanvugt/pytorch-unet/blob/master/unet.py

import math

import torch
import torch.nn as nn
import torch.nn.functional as F


class UNet(nn.Module):
    def __init__(
        self,
        in_channels=1,
        n_classes=1,
        depth=5,
        wf=6,
        padding=1,
        batch_norm=True,
        up_mode='upconv',
    ):
        super(UNet, self).__init__()
        assert up_mode in ('upconv', 'upsample')
        self.padding = padding
        self.depth = depth
        # prev_channels = in_channels

        self.convdown1 = ConvBlock(1, 32, (1, 3, 3), (0, 1, 1), batch_norm)
        self.convdown2 = ConvBlock(32, 64, (1, 3, 3), (0, 1, 1), batch_norm)
        self.convdown3 = ConvBlock(64, 128, (2, 3, 3), (0, 1, 1), batch_norm, num_convs=1)
        self.convdown4 = ConvBlock(128, 256, (2, 3, 3), (0, 1, 1), batch_norm, num_convs=1)
        self.convdown5 = ConvBlock(256, 512, (2, 3, 3), (0, 1, 1), batch_norm, num_convs=1)

        #self.convdown1 = ConvBlock(1, 32, (3, 3, 3), (1, 1, 1), batch_norm)
        #self.convdown2 = ConvBlock(32, 64, (3, 3, 3), (1, 1, 1), batch_norm)
        #self.convdown3 = ConvBlock(64, 128, (3, 3, 3), (1, 1, 1), batch_norm)
        #self.convdown4 = ConvBlock(128, 256, (3, 3, 3), (1, 1, 1), batch_norm)
        #self.convdown5 = ConvBlock(256, 512, (3, 3, 3), (1, 1, 1), batch_norm)

        self.convup4 = UpBlock(512, 256, up_mode, padding, batch_norm)
        self.convup3 = UpBlock(256, 128, up_mode, padding, batch_norm)
        self.convup2 = UpBlock(128, 64, up_mode, padding, batch_norm)
        self.convup1 = UpBlock(64, 32, up_mode, padding, batch_norm)

        self.last = nn.Conv2d(32, n_classes, kernel_size=1)

    def forward(self, x):

        down1 = self.convdown1(x)
        down1_pooled = F.max_pool3d(down1, [1, 2, 2])
        down2 = self.convdown2(down1_pooled)
        down2_pooled = F.max_pool3d(down2, [1, 2, 2])
        down3 = self.convdown3(down2_pooled)
        down3_pooled = F.max_pool3d(down3, [1, 2, 2])
        down4 = self.convdown4(down3_pooled)
        down4_pooled = F.max_pool3d(down4, [1, 2, 2])
        down5 = self.convdown5(down4_pooled)
        down5 = F.max_pool3d(down5, [2, 1, 1])

        down5 = down5.squeeze(dim=2)

        up4 = self.convup4(down5, down4)
        up3 = self.convup3(up4, down3)
        up2 = self.convup2(up3, down2)
        up1 = self.convup1(up2, down1)

        out = self.last(up1)

        return out


class ConvBlock(nn.Module):
    def __init__(self, in_size, out_size, kernel_size, padding, batch_norm, num_convs=2):
        super().__init__()
        block = []

        block.append(nn.Conv3d(in_size, out_size, kernel_size=kernel_size, padding=padding))
        block.append(nn.ReLU())
        if batch_norm:
            block.append(nn.BatchNorm3d(out_size))
        block.append(nn.Dropout3d(p=0.1))

        if num_convs == 2:
            block.append(nn.Conv3d(out_size, out_size, kernel_size=kernel_size, padding=padding))
            block.append(nn.ReLU())
            if batch_norm:
                block.append(nn.BatchNorm3d(out_size))

        self.block = nn.Sequential(*block)

    def forward(self, x):
        out = self.block(x)
        return out


class UpConvBlock(nn.Module):
    def __init__(self, in_size, out_size, padding, batch_norm):
        super().__init__()
        block = []

        block.append(nn.Conv2d(out_size, out_size, kernel_size=3, padding=int(padding)))
        block.append(nn.ReLU())
        if batch_norm:
            block.append(nn.BatchNorm2d(out_size))
        block.append(nn.Dropout2d(p=0.1))

        block.append(nn.Conv2d(out_size, out_size, kernel_size=3, padding=int(padding)))
        block.append(nn.ReLU())
        if batch_norm:
            block.append(nn.BatchNorm2d(out_size))

        self.block = nn.Sequential(*block)

    def forward(self, x):
        out = self.block(x)
        return out


class UpBlock(nn.Module):
    def __init__(self, in_size, out_size, up_mode, padding, batch_norm):
        super().__init__()
        if up_mode == 'upconv':
            self.up = nn.ConvTranspose2d(in_size, out_size, kernel_size=2, stride=2)
        elif up_mode == 'upsample':
            self.up = nn.Sequential(
                nn.Upsample(mode='bilinear', scale_factor=2),
                nn.Conv2d(in_size, out_size, kernel_size=1),
            )

        self.conv_block = UpConvBlock(in_size, out_size, padding, batch_norm)

    def forward(self, x, bridge):
        up = self.up(x)
        if bridge.shape[2] == 5:
            bridge = bridge[:, :, 2, :, :].squeeze(dim=2)
            out = torch.cat([up, bridge], 1)
        elif bridge.shape[2] in [2, 3, 4]:
            bridge = F.max_pool3d(bridge, [bridge.shape[2], 1, 1]).squeeze(dim=2)
            out = torch.cat([up, bridge], 1)
        else:
            bridge = bridge.squeeze(dim=2)
            out = torch.cat([up, bridge], 1)

        out = self.conv_block(up)

        return out


class UNetWrapper(nn.Module):
    def __init__(self, **kwargs):
        super().__init__()

        self.input_batchnorm = nn.BatchNorm3d(kwargs['in_channels'])
        self.unet = UNet(**kwargs)
        self.final = nn.Sigmoid()

        self._init_weights()

    def forward(self, input_batch):
        bn_output = self.input_batchnorm(input_batch)
        un_output = self.unet(bn_output)
        fn_output = self.final(un_output)
        return fn_output

    def _init_weights(self):                        # from Deep Learning with PyTorch book
        init_set = {
            nn.Conv2d,
            nn.Conv3d,
            nn.ConvTranspose2d,
            nn.ConvTranspose3d,
            nn.Linear,
        }
        for m in self.modules():
            if type(m) in init_set:
                nn.init.kaiming_normal_(
                    m.weight.data, mode='fan_out', nonlinearity='relu', a=0
                )
                if m.bias is not None:
                    fan_in, fan_out = \
                        nn.init._calculate_fan_in_and_fan_out(m.weight.data)
                    bound = 1 / math.sqrt(fan_out)
                    nn.init.normal_(m.bias, -bound, bound)
