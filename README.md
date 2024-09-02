# Prior Projects

Sample of code from my prior projects (in repository [jeninej](https://github.com/JenineJ/jeninej)).

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

## Echocardiogram Segmentation
*July 2021*  
Used PyTorch to create a UNet model to perform segmentation of the mitral valve on echocardiogram (cardiac ultrasound) videos. The scripts include options for data augmentation. Resulting model segmented mitral valve on each frame of test videos.

<p align="center">
  <img width=250 " src="https://github.com/user-attachments/assets/0a9d48a5-b893-481e-bd02-4bc85baaf7e4">
</p>

## Heart Failure and Coronary Artery Disease project
*May 2020*  
Published [peer-reviewed paper](https://www.ahajournals.org/doi/full/10.1161/JAHA.121.021660) on coronary artery disease (CAD) as a risk factor for heart failure with preserved ejection fraction (HFpEF). Used Stata to analyze ARIC cohort data, using epidemiology and biostatistics skills. Project involved extensive data preparation steps to create the appropriate variables.

## JJ Utils
Miscellaneous functions used across Python projects

## Other Projects
### 01 AVI Labeler
*January 2021*  
Used ImageJ's Java-like programming language to set up a video annotation workflow. This enabled a more robust team collaboration and feedback system than was possible with the many annotation software vendors I met with.

### 02 Cardiac Cath Report Info
*December 2019*  
Used regex within Python to obtain infromation from free-text cardiac catheterization procedure reports.

### 03 FDA 510k Scraping
*December 2023*  
Performed web scraping of FDA 510k submissions to identify those pertaining to cardiology AI.

### 04 Excel EEG Graphs
*June 2005*  
Joined a neuroscience lab in 2005 that analyzed and visualized EEG data in Excel. Learned Excel VBA from a book and scripted a macro to automate these steps, saving several hours of work per week.

### 05 Healthcare AI Assessment slide deck
*October 2023*  
Created slide deck for a nontechnical audience assessing AI-based healthcare tools. I plan to convert this to a series of Medium posts to help improve healthcare AI literacy.
