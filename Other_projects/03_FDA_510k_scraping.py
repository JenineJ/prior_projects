import os
import re
import urllib.request
import logging
import fitz
import pandas as pd
import pathlib
import pdfkit

#identifies FDA 510k submissions pertaining to Cardiology AI
#inspired by https://github.com/tsbischof/fda

root_data_dir = os.path.join(os.path.dirname(__file__), "data")
root_document_dir = os.path.join(root_data_dir, "documents_pma")
entries_510k_dir = "510k_radiology_2023-10-23"
entries_pma_dir = os.path.join("fda_pma", "pmaExcelReport16_2.xls")
id_parser = re.compile("(?P<kind>[A-Za-z]{1,3})"
                       "(?P<year>[0-9]{2})"
                       "(?P<index>[0-9]{4})")

os.makedirs(os.path.join(root_document_dir, "on_fda_ai_list_matches_search"), exist_ok=True)
os.makedirs(os.path.join(root_document_dir, "on_fda_ai_list_cardiac_match_only"), exist_ok=True)
os.makedirs(os.path.join(root_document_dir, "not_on_fda_ai_list_matches_search"), exist_ok=True)
os.makedirs(os.path.join(root_document_dir, "does_not_match_search"), exist_ok=True)

os.makedirs(os.path.join(root_document_dir, "cardiac_match_product_code_outside_fda_list"), exist_ok=True)


def compile_510k_df():

    entries_510k_path = os.path.join(root_data_dir, entries_510k_dir)

    entries_510k_df = pd.DataFrame()
    for file in os.listdir(entries_510k_path):
        print(file)
        if not file.startswith("."):
            df = pd.read_csv(os.path.join(entries_510k_path, file))
            entries_510k_df = entries_510k_df.append(df, ignore_index=True)

    print(entries_510k_df.shape)


def highlight_file(file_dir, file, fda_ai_list_match = False):

    file_path = os.path.join(file_dir, file)

    try:
        doc = fitz.open(file_path)

        cardiac_match_found = False
        ai_match_found = False
        # [ ] remove later
        product_code_found = False

        for page in doc:
            pg = page.get_textpage()

            product_code_matches = list()
            for product_code in ["QIH", "QVD", "QXO", "QXX", "QAS", "QFM", "QYE", "QJU"]:
                product_code_matches.extend(page.search_for(product_code, textpage=pg))

            if len(product_code_matches) > 0:
                product_code_found = True

            cardiac_matches = list()
            for cardiac_term in ["cardiology", "cardiovascular", "cardiac", "coronary", "heart", "myocardial"]:
                cardiac_matches.extend(page.search_for(cardiac_term, textpage=pg))
            for cardiac_match in cardiac_matches:
                page.add_highlight_annot(cardiac_match)
            if len(cardiac_matches) > 0:
                cardiac_match_found = True

            ai_matches = list()
            for ai_term in ["artificial intelligence", "machine learning", "deep learning", "neural network", "convolution", " AI ", " AI-", " AI)", " AI.", " AI;", " AI:", "(AI-", "(AI)", "(AI ", "AI/", "deep-learning", "machine-learning"]:  #previous last was " AI:"
                ai_matches.extend(page.search_for(ai_term, textpage=pg))
            for ai_match in ai_matches:
                highlight = page.add_highlight_annot(ai_match)
                highlight.set_colors(stroke=[1, 0.8, 0.8])
                highlight.update()
            if len(ai_matches) > 0:
                ai_match_found = True

        if (cardiac_match_found == True) and (ai_match_found == True) and (fda_ai_list_match == True):
            doc.save(file_path, incremental=True, encryption=fitz.PDF_ENCRYPT_KEEP)
            os.rename(file_path, os.path.join(root_document_dir, "on_fda_ai_list_matches_search", file))
        elif (cardiac_match_found == True) and (ai_match_found == False) and (fda_ai_list_match == True):
            os.rename(file_path, os.path.join(root_document_dir, "on_fda_ai_list_cardiac_match_only", file))
        elif (cardiac_match_found == True) and (ai_match_found == True) and (fda_ai_list_match == False):
            doc.save(file_path, incremental=True, encryption=fitz.PDF_ENCRYPT_KEEP)
            os.rename(file_path, os.path.join(root_document_dir, "not_on_fda_ai_list_matches_search", file))
        elif (cardiac_match_found == True) and (product_code_found == True):
            os.rename(file_path, os.path.join(root_document_dir, "cardiac_match_product_code_outside_fda_list", file))
        else:
            os.rename(file_path, os.path.join(root_document_dir, "does_not_match_search", file))
    except Exception as error:
        with open(os.path.join(root_document_dir, "unable_to_search.txt"), "a") as f:
            f.write("{0} {1}\n".format(file, error))


def retrieve(number_510k, destination_dir = root_document_dir, force=False):

    dst_filename = os.path.join(destination_dir, number_510k + ".pdf")
    parsed = id_parser.search(number_510k)

    urls_to_try = [
        "https://www.accessdata.fda.gov/cdrh_docs/pdf{0}/{1}.pdf".format(
            parsed.group("year").lstrip("0"), number_510k),
        "https://www.accessdata.fda.gov/cdrh_docs/pdf/{0}.pdf".format(
            number_510k)
    ]

    if force or not os.path.exists(dst_filename):

        downloaded = False

        for url in urls_to_try:
            # nested try?
            try:
                urllib.request.urlretrieve(url, dst_filename)
                downloaded = True
                print('Got', number_510k)
                break
                #return
            except urllib.error.HTTPError:   #as err:
                pass

        if downloaded == False:
            with open(os.path.join(destination_dir, "unable_to_download.txt"), "a") as f:
                f.write(number_510k + "\n")

def retrieve_pma(pma_number, destination_dir = root_document_dir):
    dst_filename = os.path.join(destination_dir, pma_number)
    parsed = id_parser.search(pma_number)

    overview_url = "https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfpma/pma.cfm?ID=" + pma_number
    summary_url = "https://www.accessdata.fda.gov/cdrh_docs/pdf{0}/{1}B.pdf".format(parsed.group("year").lstrip("0"), pma_number)

    try:
        urllib.request.urlretrieve(summary_url, dst_filename + "_summary.pdf")
    except:
        try:
            pdfkit.from_url(overview_url, dst_filename + "_overview.pdf")
        #urllib.request.urlretrieve(overview_url, dst_filename)
        except:   # [ ] specify error
            with open(os.path.join(destination_dir, "unable_to_download.txt"), "a") as f:
                f.write(pma_number + "\n")




files = (file for file in os.listdir(root_document_dir) if os.path.isfile(os.path.join(root_document_dir, file)))

for file in files:
    highlight_file(root_document_dir, file)

