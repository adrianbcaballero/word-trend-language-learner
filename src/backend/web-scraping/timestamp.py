'''
=================================================================
Script is used to add time stamp
to initial csv file (unigram_freq.csv)
=================================================================
'''

import pandas as pd
from datetime import datetime

df = pd.read_csv('./data/unigram_freq.csv')

df['date'] = datetime.now().strftime('%m-%d-%Y')

df.to_csv('./data/unigram_freq.csv', index=False)

print('time added to CSV file successfully.')

