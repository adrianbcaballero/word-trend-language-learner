'''
=================================================================
The python file does the following:
-Scrape public website for words used
-Cleans the data 
-Keeps count of word frequency
-Creats CSV file in /data folder to show word, count, and date
=================================================================
'''

import requests
from bs4 import BeautifulSoup
import csv
import os
import re
from datetime import datetime

'''
=================================================================
Method that allows cleaning of data 
(converts to lowercase, removes all symbols, extra spaces)
=================================================================
'''
def clean_text(text):
    #removing symbols
    cleaned_text = re.sub(r"[',:)–($‘%.’\"?-]", "", text)
    #converting to lowercase and removing extra spaces
    cleaned_text = ' '.join(cleaned_text.split()).lower()
    return cleaned_text

'''
=================================================================
Update word count in csv file 
=================================================================
'''
word_counts= {}

def update_word_counts(text, word_counts):
    cleaned_text = clean_text(text)
    words = cleaned_text.split()
    for word in words:
        if len(word) >=2:
            word_counts[word] = word_counts.get(word, 0) + 1

'''
=================================================================
First site to scrape is CNN.com
scrapes home page, opinion, entertainment, underscored, and style
=================================================================
'''
cnn_main_url= 'https://www.cnn.com/'
cnn_opinions_url = 'https://www.cnn.com/opinions/'
cnn_entertainment_url = 'https://www.cnn.com/entertainment/'
cnn_underscored_url = 'https://www.cnn.com/cnn-underscored/'
cnn_style_url = 'https://www.cnn.com/style/'

def scrape_cnn(url, word_counts):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")
    #get the elements with the data-editable attribute 
    editable_elements = soup.find_all(attrs={'data-editable': True})

    for element in editable_elements:
        next_element = element.next_element
        while next_element and not isinstance(next_element, str):
            next_element = next_element.next_element
        if next_element and next_element.strip():
            update_word_counts(next_element.strip(), word_counts)

scrape_cnn(cnn_main_url, word_counts)
scrape_cnn(cnn_entertainment_url, word_counts)
scrape_cnn(cnn_opinions_url, word_counts)
scrape_cnn(cnn_underscored_url, word_counts)
scrape_cnn(cnn_style_url, word_counts)

'''
=================================================================
Second site to script is CBS
scrapes home page, opinion, entertainment, and essentials pages
=================================================================
'''


'''
=================================================================
Creating the new CSV
=================================================================
'''

filter_word_count = {word: count for word, count in word_counts.items() if count >=10}

folder_path = './data/weekly_scraped_data'

week = datetime.now().strftime('%W')
month = datetime.now().strftime('%B')
year = datetime.now().strftime('%Y')

output_file = os.path.join(folder_path, f'scraped_data_week{week}_{month}_{year}.csv')

with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['word','count', 'date'])
    for word, count in filter_word_count.items():
        csv_writer.writerow([word, count, datetime.now().strftime('%m-%d-%Y')])

print("Weekly scraping is complete!")

