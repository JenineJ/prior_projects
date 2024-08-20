## ECG deep learning
*May 2020*  
Used TensorFlow to create a deep learning model for electrocardiogram (ECG) analysis based on [WaveNet](https://arxiv.org/pdf/1609.03499), a deep learning model for audio signals. Diagram from creators of WaveNet:
<p align="center">
  <img width="550" src="https://github.com/user-attachments/assets/97951114-3a39-4cee-b84b-673801bb9782">
</p>

I created one version to take in one-dimensional input - the ECG amplitudes for a single lead. Also created another version to take in two-dimensional input, with each lead of a 12-lead ECG along the second dimension.
<p align="center">
  <img width=450" src="https://github.com/user-attachments/assets/49c4d133-eab2-4c8b-9ddc-f7d686afaf68">
</p>

The model was used for various predictions, including estimation of age, which was also performed by a group at the Mayo Clinic using a convolutional neural network. [Their CNN](https://www.ahajournals.org/doi/full/10.1161/CIRCEP.119.007284) was trained on ~500,000 ECGs. Their results:  
<p align="center">
  <img width=350 " src="https://github.com/user-attachments/assets/82757b3a-3c53-45b9-9cb3-b52c800f44cb">
</p>

I created a deep learning model that emulated the model architecture described in the Mayo Clinic paper. Below is the comparison of performance after using the same set of ~13,000 hospital ECGs to train my WaveNet-based model (35,500 parameters trained) and the emulated Mayo Clinic model (197,000 parameters trained).
<p align="center">
  <img width=550 " src="https://github.com/user-attachments/assets/41adf863-fae2-4a09-9b62-660ea2387161">
</p>
