#!/usr/bin/env python3

import os
import numpy as np
import pandas as pd
import pickle
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-x", "--start", dest = "start", type = "int")
parser.add_option("-y", "--end", dest = "end", type = "int")
(options, args) = parser.parse_args()
start = options.start
end = options.end

df = pd.read_csv('/mnt/obi0/jjohn2/projects/ecg/MGH_60k_500hz_ecgs_with_age_18_100.csv')


df = df[start:end]

def get_leads(x):  
    global age_nparray
    global leads_nparray
    global female_nparray
    global pr_nparray
    global filename_nparray

    
    try:
        folder = x['study_filename'][0:5]
        
        with open('/mnt/obi0/phi/ecg/convertedData/MGH/' + folder + '/' + x['study_filename'] + '.dict', 'rb') as f:
            ecg_dict = pickle.load(f)
            
            leads_concatenated = ecg_dict['voltage']['I']
        
            if leads_concatenated.shape[0] == 5000:

                for key in ['II', 'III', 'aVR', 'aVL', 'aVF', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6']:
                    leads_concatenated = np.concatenate((leads_concatenated, ecg_dict['voltage'][key]))
                    
                leads_concatenated = leads_concatenated.reshape((1, leads_concatenated.shape[0]))
            
                leads_nparray = np.vstack((leads_nparray, leads_concatenated))
                age_nparray = np.concatenate((age_nparray, np.asarray([x['age']])))
                female_nparray = np.concatenate((female_nparray, np.asarray([x['female']])))
                pr_nparray = np.concatenate((pr_nparray, np.asarray([x['PRInterval']])))
                filename_nparray = np.concatenate((filename_nparray, np.asarray([x['study_filename']])))
    
        ecg_pulled = 1
    
    except:
        ecg_pulled = 0
    
    return ecg_pulled



df.name = 'MGH_60k_500hz_ecgs_age_18_100_section_' + str(start)

age_nparray= np.zeros((1,))
female_nparray= np.zeros((1,))
pr_nparray = np.zeros((1,))
filename_nparray = np.zeros((1,))
leads_nparray= np.zeros((1, 60000))
df['ecg_pulled'] = df.apply(get_leads, axis=1)

age_nparray = age_nparray[1:]
age_nparray = age_nparray.astype(int)
female_nparray = female_nparray[1:]
female_nparray = female_nparray.astype(int)
pr_nparray = pr_nparray[1:]
pr_nparray = pr_nparray.astype(int)
filename_nparray = filename_nparray[1:]
    
leads_nparray = leads_nparray[1:, :]
leads_nparray = leads_nparray.reshape(leads_nparray.shape[0], leads_nparray.shape[1], 1)
    
np.save(('/mnt/obi0/jjohn2/projects/ecg/' + df.name + '_X'), leads_nparray)
np.save(('/mnt/obi0/jjohn2/projects/ecg/' + df.name + '_yfemale'), female_nparray)
np.save(('/mnt/obi0/jjohn2/projects/ecg/' + df.name + '_ypr'), pr_nparray)
np.save(('/mnt/obi0/jjohn2/projects/ecg/' + df.name + '_yage'), age_nparray)
np.save(('/mnt/obi0/jjohn2/projects/ecg/' + df.name + '_filename'), filename_nparray)


df.to_csv('/mnt/obi0/jjohn2/projects/ecg/MGH_60k_500hz_ecgs_with_age_18_100_pulledecgcol_' + str(start) + '.csv')
